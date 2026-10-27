import { HttpException } from '@nestjs/common';

export const DOMAIN = 'catalog';

export const CatalogErrorCode = {
  MONTH_NOT_FOUND: 'MONTH_NOT_FOUND',
  ITEM_NOT_FOUND: 'ITEM_NOT_FOUND',
  MISSING_SSO_ID: 'MISSING_SSO_ID',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
} as const;

export type CatalogErrorCode =
  (typeof CatalogErrorCode)[keyof typeof CatalogErrorCode];

export const CATALOG_ERRORS: Record<
  CatalogErrorCode,
  { message: string; status: number }
> = {
  MONTH_NOT_FOUND: { message: 'Month not found', status: 404 },
  ITEM_NOT_FOUND: { message: 'Item not found', status: 404 },
  MISSING_SSO_ID: { message: 'Missing x-sso-id header', status: 400 },
  VALIDATION_ERROR: { message: 'Validation failed', status: 400 },
  INTERNAL_ERROR: { message: 'Internal server error', status: 500 },
};

/** Serialized into the contract body: { domain, code, message } */
export class DomainError extends HttpException {
  constructor(public readonly code: CatalogErrorCode, messageOverride?: string) {
    const def = CATALOG_ERRORS[code];
    super(
      { domain: DOMAIN, code, message: messageOverride ?? def.message },
      def.status,
    );
  }
}
