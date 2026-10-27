import { Inject, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { randomUUID, randomBytes, randomInt } from 'crypto';
import {
  BCRYPT_ROUNDS,
  TOKEN_BYTES,
  RESET_TOKEN_TTL_MS,
  OTP_DIGITS,
  OTP_TTL_MS,
  OTP_MAX_ATTEMPTS,
  SETUP_TICKET_TTL_MS,
} from '../../shared/constants';
import * as bcrypt from 'bcryptjs';
import {
  USER_REPOSITORY,
  UserRepositoryPort,
} from '../../domain/port/user.repository.port';
import {
  PENDING_REGISTRATION_REPOSITORY,
  PendingRegistrationRepositoryPort,
} from '../../domain/port/pending-registration.repository.port';
import { MAILER, MailerPort } from '../../domain/port/mailer.port';
import {
  CUSTOMER_CLIENT,
  CustomerClientPort,
} from '../../domain/port/customer.client.port';
import { User } from '../../domain/model/user';
import { PendingRegistration } from '../../domain/model/pending-registration';
import { DomainError, AuthErrorCode } from '../../shared/errors';
import {
  AuthResult,
  AuthTokens,
  LoginCommand,
  RegisterCommand,
  RegisterResult,
  VerifyOtpCommand,
  VerifyOtpResult,
  SetPasswordCommand,
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
    @Inject(PENDING_REGISTRATION_REPOSITORY)
    private readonly pending: PendingRegistrationRepositoryPort,
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

  /**
   * Step 1 — start registration: validate uniqueness, create/replace a
   * pending row, email a 6-digit OTP. No account or session is created yet.
   */
  async register(cmd: RegisterCommand): Promise<RegisterResult> {
    const email = cmd.email.toLowerCase().trim();

    const existing = await this.users.findByEmail(email);
    if (existing) {
      throw new DomainError(AuthErrorCode.EMAIL_ALREADY_USED);
    }
    // fail fast if the username is already taken (before emailing an OTP)
    const takenBy = await this.customer.findSsoIdByUsername(cmd.username);
    if (takenBy) {
      throw new DomainError(AuthErrorCode.USERNAME_TAKEN);
    }

    const otp = this.generateOtp();
    const otpHash = await bcrypt.hash(otp, BCRYPT_ROUNDS);
    const pending = new PendingRegistration({
      email,
      title: cmd.title,
      username: cmd.username,
      firstName: cmd.firstName,
      lastName: cmd.lastName,
      otpHash,
      otpExpiresAt: new Date(Date.now() + OTP_TTL_MS),
    });
    await this.pending.upsertByEmail(pending);

    try {
      await this.mailer.sendOtpEmail(email, otp);
    } catch {
      /* dev: OTP logged by mailer */
    }
    return { email, otpExpiresInSec: Math.floor(OTP_TTL_MS / 1000) };
  }

  /**
   * Step 2 — verify the OTP. On success, mark verified and issue a short-lived
   * setup ticket required to set the password.
   */
  async verifyOtp(cmd: VerifyOtpCommand): Promise<VerifyOtpResult> {
    const email = cmd.email.toLowerCase().trim();
    const pending = await this.pending.findByEmail(email);
    if (!pending) {
      throw new DomainError(AuthErrorCode.PENDING_NOT_FOUND);
    }
    if (pending.isOtpExpired()) {
      throw new DomainError(AuthErrorCode.OTP_EXPIRED);
    }
    if (pending.attempts >= OTP_MAX_ATTEMPTS) {
      throw new DomainError(AuthErrorCode.TOO_MANY_OTP_ATTEMPTS);
    }

    const ok = await bcrypt.compare(cmd.otp, pending.otpHash);
    if (!ok) {
      pending.attempts += 1;
      await this.pending.update(pending);
      throw new DomainError(AuthErrorCode.INVALID_OTP);
    }

    pending.emailVerified = true;
    pending.setupTicket = randomBytes(TOKEN_BYTES).toString('hex');
    pending.setupTicketExpiresAt = new Date(Date.now() + SETUP_TICKET_TTL_MS);
    pending.attempts = 0;
    await this.pending.update(pending);

    return { email, setupTicket: pending.setupTicket };
  }

  /** Re-send a fresh OTP for an in-progress registration. */
  async resendOtp(emailRaw: string): Promise<RegisterResult> {
    const email = emailRaw.toLowerCase().trim();
    const pending = await this.pending.findByEmail(email);
    if (!pending) {
      throw new DomainError(AuthErrorCode.PENDING_NOT_FOUND);
    }
    const otp = this.generateOtp();
    pending.otpHash = await bcrypt.hash(otp, BCRYPT_ROUNDS);
    pending.otpExpiresAt = new Date(Date.now() + OTP_TTL_MS);
    pending.attempts = 0;
    await this.pending.update(pending);
    try {
      await this.mailer.sendOtpEmail(email, otp);
    } catch {
      /* dev: OTP logged by mailer */
    }
    return { email, otpExpiresInSec: Math.floor(OTP_TTL_MS / 1000) };
  }

  /**
   * Step 3 — set the password and finish the account. Requires the setup
   * ticket from verify-otp. Provisions the customer profile, creates the
   * (already verified) user, deletes the pending row, and logs the user in.
   */
  async setPassword(cmd: SetPasswordCommand): Promise<AuthResult> {
    const email = cmd.email.toLowerCase().trim();
    const pending = await this.pending.findByEmail(email);
    if (!pending) {
      throw new DomainError(AuthErrorCode.PENDING_NOT_FOUND);
    }
    if (!pending.emailVerified) {
      throw new DomainError(AuthErrorCode.EMAIL_NOT_VERIFIED);
    }
    if (!pending.isTicketValid(cmd.setupTicket)) {
      throw new DomainError(AuthErrorCode.INVALID_SETUP_TICKET);
    }

    // guard against a race: email registered elsewhere in the meantime
    const existing = await this.users.findByEmail(email);
    if (existing) {
      await this.pending.deleteByEmail(email);
      throw new DomainError(AuthErrorCode.EMAIL_ALREADY_USED);
    }

    // provision the customer profile first (keeps the two stores consistent)
    const ssoId = randomUUID();
    await this.customer.createProfile({
      ssoId,
      title: pending.title,
      username: pending.username,
      firstName: pending.firstName,
      lastName: pending.lastName,
    });

    const passwordHash = await bcrypt.hash(cmd.password, BCRYPT_ROUNDS);
    const user = User.create({ ssoId, email, passwordHash });
    user.markEmailVerified(); // OTP already proved ownership
    const saved = await this.users.create(user);

    await this.pending.deleteByEmail(email);
    return this.buildResult(saved);
  }

  /** Generate a zero-padded numeric OTP of OTP_DIGITS length. */
  private generateOtp(): string {
    const max = 10 ** OTP_DIGITS;
    return randomInt(0, max).toString().padStart(OTP_DIGITS, '0');
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
