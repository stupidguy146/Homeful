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
