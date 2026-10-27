import { HttpException } from '@nestjs/common';

export const DOMAIN = 'gateway';

export const GatewayErrorCode = {
  MISSING_ACCESS_TOKEN: 'MISSING_ACCESS_TOKEN',
  INVALID_ACCESS_TOKEN: 'INVALID_ACCESS_TOKEN',
  UPSTREAM_UNAVAILABLE: 'UPSTREAM_UNAVAILABLE',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
} as const;

export type GatewayErrorCode =
  (typeof GatewayErrorCode)[keyof typeof GatewayErrorCode];

export const GATEWAY_ERRORS: Record<
  GatewayErrorCode,
  { message: string; status: number }
> = {
  MISSING_ACCESS_TOKEN: { message: 'Missing access token', status: 401 },
  INVALID_ACCESS_TOKEN: {
    message: 'Access token is invalid or expired',
    status: 401,
  },
  UPSTREAM_UNAVAILABLE: { message: 'Upstream service unavailable', status: 502 },
  INTERNAL_ERROR: { message: 'Internal server error', status: 500 },
};

/** Serialized into the contract body: { domain, code, message } */
export class DomainError extends HttpException {
  constructor(public readonly code: GatewayErrorCode, messageOverride?: string) {
    const def = GATEWAY_ERRORS[code];
    super(
      { domain: DOMAIN, code, message: messageOverride ?? def.message },
      def.status,
    );
  }
}
