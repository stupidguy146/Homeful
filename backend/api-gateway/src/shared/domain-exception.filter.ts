import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import { GatewayErrorCode, DOMAIN } from './errors';

interface ErrorBody {
  domain: string;
  code: string;
  message: string;
}

/**
 * Normalizes gateway errors into { domain, code, message } and — importantly —
 * passes through error bodies that already follow the contract (i.e. relayed
 * from an upstream service), so the original domain/code reaches the client.
 */
@Catch()
export class DomainExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(DomainExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let body: ErrorBody = {
      domain: DOMAIN,
      code: GatewayErrorCode.INTERNAL_ERROR,
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
        // already a contract body — either a gateway DomainError or an
        // upstream error relayed by the proxy. Pass it through unchanged.
        body = resp as unknown as ErrorBody;
      } else {
        // upstream sent a non-contract body, or a bare Nest exception
        body = {
          domain: DOMAIN,
          code:
            status === HttpStatus.BAD_GATEWAY
              ? GatewayErrorCode.UPSTREAM_UNAVAILABLE
              : GatewayErrorCode.INTERNAL_ERROR,
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
    return m ?? 'Error';
  }
}
