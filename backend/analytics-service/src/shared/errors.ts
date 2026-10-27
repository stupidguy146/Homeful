import { HttpException } from '@nestjs/common';

export const DOMAIN = 'analytics';

export const AnalyticsErrorCode = {
  MONTH_NOT_FOUND: 'MONTH_NOT_FOUND',
  MISSING_SSO_ID: 'MISSING_SSO_ID',
  UPSTREAM_UNAVAILABLE: 'UPSTREAM_UNAVAILABLE',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
} as const;

export type AnalyticsErrorCode =
  (typeof AnalyticsErrorCode)[keyof typeof AnalyticsErrorCode];

export const ANALYTICS_ERRORS: Record<
  AnalyticsErrorCode,
  { message: string; status: number }
> = {
  MONTH_NOT_FOUND: { message: 'Month not found', status: 404 },
  MISSING_SSO_ID: { message: 'Missing x-sso-id header', status: 400 },
  UPSTREAM_UNAVAILABLE: { message: 'Catalog service unavailable', status: 502 },
  VALIDATION_ERROR: { message: 'Validation failed', status: 400 },
  INTERNAL_ERROR: { message: 'Internal server error', status: 500 },
};

/** Serialized into the contract body: { domain, code, message } */
export class DomainError extends HttpException {
  constructor(
    public readonly code: AnalyticsErrorCode,
    messageOverride?: string,
  ) {
    const def = ANALYTICS_ERRORS[code];
    super(
      { domain: DOMAIN, code, message: messageOverride ?? def.message },
      def.status,
    );
  }
}
