/** Shared magic values for auth-service, centralized. */

/** HTTP header the gateway uses to forward the authenticated identity. */
export const SSO_ID_HEADER = 'x-sso-id';

/** Authorization scheme prefix for bearer tokens. */
export const BEARER_PREFIX = 'Bearer ';

/** bcrypt cost factor for password hashing. */
export const BCRYPT_ROUNDS = 10;

/** Byte length for random email-verify / password-reset tokens. */
export const TOKEN_BYTES = 32;

/** Password reset token lifetime (ms). */
export const RESET_TOKEN_TTL_MS = 60 * 60 * 1000; // 1 hour

/** Registration OTP: number of digits. */
export const OTP_DIGITS = 6;

/** Registration OTP lifetime (ms). */
export const OTP_TTL_MS = 10 * 60 * 1000; // 10 minutes

/** Max wrong OTP attempts before the code is invalidated. */
export const OTP_MAX_ATTEMPTS = 5;

/** Lifetime (ms) of the setup ticket issued after OTP verification. */
export const SETUP_TICKET_TTL_MS = 15 * 60 * 1000; // 15 minutes
