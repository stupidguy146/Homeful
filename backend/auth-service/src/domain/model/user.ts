/**
 * Domain model for a user (identity). Pure TypeScript, no framework/DB deps.
 * - `id`: running integer PK (internal to auth)
 * - `ssoId`: UUID used as the JWT `sub` and the cross-service reference
 *   (customer/catalog link to it). This is what "ssoId" means everywhere.
 * auth owns only credentials (email + password). Profile fields
 * (username, first/last name, ...) live in customer-service.
 */
export class User {
  emailVerified: boolean;
  verifyToken: string | null;
  resetToken: string | null;
  resetTokenExpiresAt: Date | null;

  constructor(
    public readonly ssoId: string,
    public readonly email: string,
    public passwordHash: string,
    public readonly createdAt: Date,
    opts?: {
      id?: number;
      emailVerified?: boolean;
      verifyToken?: string | null;
      resetToken?: string | null;
      resetTokenExpiresAt?: Date | null;
    },
  ) {
    this.id = opts?.id;
    this.emailVerified = opts?.emailVerified ?? false;
    this.verifyToken = opts?.verifyToken ?? null;
    this.resetToken = opts?.resetToken ?? null;
    this.resetTokenExpiresAt = opts?.resetTokenExpiresAt ?? null;
  }

  readonly id?: number;

  static create(params: {
    ssoId: string;
    email: string;
    passwordHash: string;
    verifyToken?: string | null;
  }): User {
    return new User(
      params.ssoId,
      params.email.toLowerCase().trim(),
      params.passwordHash,
      new Date(),
      { emailVerified: false, verifyToken: params.verifyToken ?? null },
    );
  }

  markEmailVerified(): void {
    this.emailVerified = true;
    this.verifyToken = null;
  }
}
