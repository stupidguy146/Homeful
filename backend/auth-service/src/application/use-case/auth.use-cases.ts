import { Inject, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { randomUUID, randomBytes } from 'crypto';
import {
  BCRYPT_ROUNDS,
  TOKEN_BYTES,
  RESET_TOKEN_TTL_MS,
} from '../../shared/constants';
import * as bcrypt from 'bcryptjs';
import {
  USER_REPOSITORY,
  UserRepositoryPort,
} from '../../domain/port/user.repository.port';
import { MAILER, MailerPort } from '../../domain/port/mailer.port';
import {
  CUSTOMER_CLIENT,
  CustomerClientPort,
} from '../../domain/port/customer.client.port';
import { User } from '../../domain/model/user';
import { DomainError, AuthErrorCode } from '../../shared/errors';
import {
  AuthResult,
  AuthTokens,
  LoginCommand,
  RegisterCommand,
} from '../dto/commands';

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

/**
 * Application use-cases for authentication.
 * - passwords hashed with bcrypt (never stored in plaintext)
 * - stateless JWT (sub = ssoId); access + refresh tokens
 * - username + first/last name live in customer-service; auth provisions the
 *   profile at registration and resolves username → ssoId at login.
 */
@Injectable()
export class AuthUseCases {
  private readonly accessTtl: string;
  private readonly refreshTtl: string;
  private readonly refreshSecret: string;
  private readonly appBaseUrl: string;

  constructor(
    @Inject(USER_REPOSITORY)
    private readonly users: UserRepositoryPort,
    @Inject(MAILER)
    private readonly mailer: MailerPort,
    @Inject(CUSTOMER_CLIENT)
    private readonly customer: CustomerClientPort,
    private readonly jwt: JwtService,
    config: ConfigService,
  ) {
    this.accessTtl = config.get<string>('JWT_ACCESS_TTL', '15m');
    this.refreshTtl = config.get<string>('JWT_REFRESH_TTL', '7d');
    this.refreshSecret = config.get<string>(
      'JWT_REFRESH_SECRET',
      'dev_refresh_secret_change_me',
    );
    this.appBaseUrl = config.get<string>(
      'APP_BASE_URL',
      'http://localhost:3000',
    );
  }

  async register(cmd: RegisterCommand): Promise<AuthResult> {
    const email = cmd.email.toLowerCase().trim();
    const existing = await this.users.findByEmail(email);
    if (existing) {
      throw new DomainError(AuthErrorCode.EMAIL_ALREADY_USED);
    }

    // provision the customer profile FIRST so a taken username fails before we
    // create the credential (keeps the two stores consistent).
    const ssoId = randomUUID();
    await this.customer.createProfile({
      ssoId,
      username: cmd.username,
      firstName: cmd.firstName,
      lastName: cmd.lastName,
    });

    const passwordHash = await bcrypt.hash(cmd.password, BCRYPT_ROUNDS);
    const verifyToken = randomBytes(TOKEN_BYTES).toString('hex');
    const user = User.create({ ssoId, email, passwordHash, verifyToken });
    const saved = await this.users.create(user);

    const verifyUrl = `${this.appBaseUrl}/api/auth/verify-email?token=${verifyToken}`;
    try {
      await this.mailer.sendVerificationEmail(saved.email, verifyUrl);
    } catch {
      /* dev: link logged by mailer */
    }
    return this.buildResult(saved);
  }

  /** Login with either an email or a username. */
  async login(cmd: LoginCommand): Promise<AuthResult> {
    const identifier = cmd.identifier.trim();
    let user: User | null;

    if (EMAIL_RE.test(identifier)) {
      user = await this.users.findByEmail(identifier);
    } else {
      // treat as username → resolve to ssoId via customer-service
      const ssoId = await this.customer.findSsoIdByUsername(identifier);
      user = ssoId ? await this.users.findBySsoId(ssoId) : null;
    }

    if (!user) {
      throw new DomainError(AuthErrorCode.INVALID_CREDENTIALS);
    }
    const ok = await bcrypt.compare(cmd.password, user.passwordHash);
    if (!ok) {
      throw new DomainError(AuthErrorCode.INVALID_CREDENTIALS);
    }
    return this.buildResult(user);
  }

  /** Verify a refresh token and issue a fresh token pair (rotation). */
  async refresh(refreshToken: string): Promise<AuthTokens> {
    let payload: { sub: string };
    try {
      payload = await this.jwt.verifyAsync(refreshToken, {
        secret: this.refreshSecret,
      });
    } catch {
      throw new DomainError(AuthErrorCode.INVALID_REFRESH_TOKEN);
    }
    const user = await this.users.findBySsoId(payload.sub);
    if (!user) {
      throw new DomainError(AuthErrorCode.USER_NOT_FOUND);
    }
    return this.signTokens(user);
  }

  /** Return the current user's auth-side profile (ssoId + email + verified). */
  async me(ssoId: string): Promise<{
    ssoId: string;
    email: string;
    emailVerified: boolean;
  }> {
    const user = await this.users.findBySsoId(ssoId);
    if (!user) {
      throw new DomainError(AuthErrorCode.USER_NOT_FOUND);
    }
    return {
      ssoId: user.ssoId,
      email: user.email,
      emailVerified: user.emailVerified,
    };
  }

  /** Change the current user's password (requires the old password). */
  async changePassword(
    ssoId: string,
    oldPassword: string,
    newPassword: string,
  ): Promise<void> {
    const user = await this.users.findBySsoId(ssoId);
    if (!user) {
      throw new DomainError(AuthErrorCode.USER_NOT_FOUND);
    }
    const ok = await bcrypt.compare(oldPassword, user.passwordHash);
    if (!ok) {
      throw new DomainError(AuthErrorCode.WRONG_OLD_PASSWORD);
    }
    user.passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    await this.users.update(user);
  }

  async verifyEmail(token: string): Promise<void> {
    const user = await this.users.findByVerifyToken(token);
    if (!user) {
      throw new DomainError(AuthErrorCode.INVALID_VERIFY_TOKEN);
    }
    user.markEmailVerified();
    await this.users.update(user);
  }

  async resendVerification(ssoId: string): Promise<void> {
    const user = await this.users.findBySsoId(ssoId);
    if (!user) {
      throw new DomainError(AuthErrorCode.USER_NOT_FOUND);
    }
    if (user.emailVerified) return;
    user.verifyToken = randomBytes(TOKEN_BYTES).toString('hex');
    await this.users.update(user);
    const verifyUrl = `${this.appBaseUrl}/api/auth/verify-email?token=${user.verifyToken}`;
    try {
      await this.mailer.sendVerificationEmail(user.email, verifyUrl);
    } catch {
      /* dev: link logged by mailer */
    }
  }

  async forgotPassword(email: string): Promise<void> {
    const user = await this.users.findByEmail(email);
    if (!user) return;
    user.resetToken = randomBytes(TOKEN_BYTES).toString('hex');
    user.resetTokenExpiresAt = new Date(Date.now() + RESET_TOKEN_TTL_MS);
    await this.users.update(user);
    const resetUrl = `${this.appBaseUrl}/reset-password?token=${user.resetToken}`;
    try {
      await this.mailer.sendPasswordResetEmail(user.email, resetUrl);
    } catch {
      /* dev: link logged by mailer */
    }
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    const user = await this.users.findByResetToken(token);
    if (
      !user ||
      !user.resetTokenExpiresAt ||
      user.resetTokenExpiresAt.getTime() < Date.now()
    ) {
      throw new DomainError(AuthErrorCode.INVALID_RESET_TOKEN);
    }
    user.passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    user.resetToken = null;
    user.resetTokenExpiresAt = null;
    await this.users.update(user);
  }

  private async signTokens(user: User): Promise<AuthTokens> {
    const payload = { sub: user.ssoId, email: user.email };
    const accessToken = await this.jwt.signAsync(payload, {
      expiresIn: this.accessTtl,
    });
    const refreshToken = await this.jwt.signAsync(
      { sub: user.ssoId },
      { secret: this.refreshSecret, expiresIn: this.refreshTtl },
    );
    return { accessToken, refreshToken };
  }

  private async buildResult(user: User): Promise<AuthResult> {
    const tokens = await this.signTokens(user);
    return {
      ...tokens,
      user: {
        ssoId: user.ssoId,
        email: user.email,
        emailVerified: user.emailVerified,
      },
    };
  }
}
