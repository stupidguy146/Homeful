import { HttpException } from '@nestjs/common';

/** Domain this service owns — included in every error response. */
export const DOMAIN = 'auth';

/** Catalog of error codes this service can emit. */
export const AuthErrorCode = {
  EMAIL_ALREADY_USED: 'EMAIL_ALREADY_USED',
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  USER_NOT_FOUND: 'USER_NOT_FOUND',
  INVALID_REFRESH_TOKEN: 'INVALID_REFRESH_TOKEN',
  MISSING_ACCESS_TOKEN: 'MISSING_ACCESS_TOKEN',
  INVALID_ACCESS_TOKEN: 'INVALID_ACCESS_TOKEN',
  WRONG_OLD_PASSWORD: 'WRONG_OLD_PASSWORD',
  INVALID_VERIFY_TOKEN: 'INVALID_VERIFY_TOKEN',
  INVALID_RESET_TOKEN: 'INVALID_RESET_TOKEN',
  USERNAME_TAKEN: 'USERNAME_TAKEN',
  PROFILE_PROVISION_FAILED: 'PROFILE_PROVISION_FAILED',
  PENDING_NOT_FOUND: 'PENDING_NOT_FOUND',
  INVALID_OTP: 'INVALID_OTP',
  OTP_EXPIRED: 'OTP_EXPIRED',
  TOO_MANY_OTP_ATTEMPTS: 'TOO_MANY_OTP_ATTEMPTS',
  EMAIL_NOT_VERIFIED: 'EMAIL_NOT_VERIFIED',
  INVALID_SETUP_TICKET: 'INVALID_SETUP_TICKET',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
} as const;

export type AuthErrorCode =
  (typeof AuthErrorCode)[keyof typeof AuthErrorCode];

/**
 * Default (English) message + HTTP status for each error code.
 * This is the single source of truth — `message` in the response is a
 * developer-facing fallback; user-facing text is localized on the client
 * using `code`.
 */
export const AUTH_ERRORS: Record<
  AuthErrorCode,
  { message: string; status: number }
> = {
  EMAIL_ALREADY_USED: { message: 'Email is already in use', status: 409 },
  INVALID_CREDENTIALS: { message: 'Invalid email or password', status: 401 },
  USER_NOT_FOUND: { message: 'User not found', status: 401 },
  INVALID_REFRESH_TOKEN: {
    message: 'Refresh token is invalid or expired',
    status: 401,
  },
  MISSING_ACCESS_TOKEN: { message: 'Missing access token', status: 401 },
  INVALID_ACCESS_TOKEN: {
    message: 'Access token is invalid or expired',
    status: 401,
  },
  WRONG_OLD_PASSWORD: { message: 'Old password is incorrect', status: 401 },
  INVALID_VERIFY_TOKEN: {
    message: 'Verification link is invalid or expired',
    status: 404,
  },
  INVALID_RESET_TOKEN: {
    message: 'Reset link is invalid or expired',
    status: 404,
  },
  USERNAME_TAKEN: { message: 'Username is already taken', status: 409 },
  PROFILE_PROVISION_FAILED: { message: 'Failed to provision profile', status: 502 },
  PENDING_NOT_FOUND: {
    message: 'No pending registration for this email',
    status: 404,
  },
  INVALID_OTP: { message: 'The OTP code is incorrect', status: 400 },
  OTP_EXPIRED: { message: 'The OTP code has expired', status: 400 },
  TOO_MANY_OTP_ATTEMPTS: {
    message: 'Too many incorrect attempts, request a new code',
    status: 429,
  },
  EMAIL_NOT_VERIFIED: {
    message: 'Please verify your email with the OTP first',
    status: 400,
  },
  INVALID_SETUP_TICKET: {
    message: 'Setup session is invalid or expired',
    status: 400,
  },
  VALIDATION_ERROR: { message: 'Validation failed', status: 400 },
  INTERNAL_ERROR: { message: 'Internal server error', status: 500 },
};

/**
 * Error carrying the owning domain + a machine-readable code. The English
 * fallback message and HTTP status are looked up from AUTH_ERRORS, so call
 * sites only pass a code. Serialized into the contract body:
 *   { domain, code, message }
 */
export class DomainError extends HttpException {
  constructor(public readonly code: AuthErrorCode, messageOverride?: string) {
    const def = AUTH_ERRORS[code];
    super(
      { domain: DOMAIN, code, message: messageOverride ?? def.message },
      def.status,
    );
  }
}
