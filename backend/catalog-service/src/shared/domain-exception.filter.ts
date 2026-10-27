import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import { CatalogErrorCode, DOMAIN } from './errors';

interface ErrorBody {
  domain: string;
  code: string;
  message: string;
}

/** Normalizes every error into { domain, code, message }. */
@Catch()
export class DomainExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(DomainExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let body: ErrorBody = {
      domain: DOMAIN,
      code: CatalogErrorCode.INTERNAL_ERROR,
      message: 'Internal server error',
    };

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const resp = exception.getResponse();
      if (
        resp &&
        typeof resp === 'object' &&
        'code' in resp &&
        'domain' in resp
      ) {
        body = resp as unknown as ErrorBody;
      } else {
        body = {
          domain: DOMAIN,
          code:
            status === HttpStatus.BAD_REQUEST
              ? CatalogErrorCode.VALIDATION_ERROR
              : status === HttpStatus.NOT_FOUND
                ? CatalogErrorCode.MONTH_NOT_FOUND
                : CatalogErrorCode.INTERNAL_ERROR,
          message: this.extractMessage(resp),
        };
      }
    } else {
      this.logger.error(exception);
    }

    res.status(status).json(body);
  }

  private extractMessage(resp: string | object): string {
    if (typeof resp === 'string') return resp;
    const m = (resp as { message?: string | string[] }).message;
    if (Array.isArray(m)) return m.join('\n');
    return m ?? 'Bad request';
  }
}
