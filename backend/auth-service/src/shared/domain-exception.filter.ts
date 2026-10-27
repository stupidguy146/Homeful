import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import { AuthErrorCode, DOMAIN } from './errors';

/** The shape every error response follows. */
interface ErrorBody {
  domain: string;
  code: string;
  message: string;
}

/**
 * Normalizes every thrown error into the contract body { domain, code, message }.
 * - DomainError already carries { domain, code, message }
 * - Nest HttpException (incl. ValidationPipe 400) → mapped to a code
 * - anything else → 500 INTERNAL_ERROR
 */
@Catch()
export class DomainExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(DomainExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let body: ErrorBody = {
      domain: DOMAIN,
      code: AuthErrorCode.INTERNAL_ERROR,
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
        // already a DomainError contract body
        body = resp as unknown as ErrorBody;
      } else {
        // built-in HttpException (e.g. ValidationPipe) → map to a code
        const msg = this.extractMessage(resp);
        body = {
          domain: DOMAIN,
          code:
            status === HttpStatus.BAD_REQUEST
              ? AuthErrorCode.VALIDATION_ERROR
              : AuthErrorCode.INTERNAL_ERROR,
          message: msg,
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
