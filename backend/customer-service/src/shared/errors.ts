import { HttpException } from '@nestjs/common';

export const DOMAIN = 'customer';

export const CustomerErrorCode = {
  MISSING_SSO_ID: 'MISSING_SSO_ID',
  USERNAME_TAKEN: 'USERNAME_TAKEN',
  PROFILE_NOT_FOUND: 'PROFILE_NOT_FOUND',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
} as const;

export type CustomerErrorCode =
  (typeof CustomerErrorCode)[keyof typeof CustomerErrorCode];

export const CUSTOMER_ERRORS: Record<
  CustomerErrorCode,
  { message: string; status: number }
> = {
  MISSING_SSO_ID: { message: 'Missing x-sso-id header', status: 400 },
  USERNAME_TAKEN: { message: 'Username is already taken', status: 409 },
  PROFILE_NOT_FOUND: { message: 'Profile not found', status: 404 },
  VALIDATION_ERROR: { message: 'Validation failed', status: 400 },
  INTERNAL_ERROR: { message: 'Internal server error', status: 500 },
};

/** Serialized into the contract body: { domain, code, message } */
export class DomainError extends HttpException {
  constructor(public readonly code: CustomerErrorCode, messageOverride?: string) {
    const def = CUSTOMER_ERRORS[code];
    super(
      { domain: DOMAIN, code, message: messageOverride ?? def.message },
      def.status,
    );
  }
}
