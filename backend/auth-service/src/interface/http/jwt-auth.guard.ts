import {
  CanActivate,
  ExecutionContext,
  Injectable,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { DomainError, AuthErrorCode } from '../../shared/errors';
import { BEARER_PREFIX } from '../../shared/constants';

/**
 * Inbound guard: validates the Bearer access token and attaches
 * the decoded user id to the request as `userId`.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<Request>();
    const header = req.headers['authorization'];
    if (!header || !header.startsWith(BEARER_PREFIX)) {
      throw new DomainError(AuthErrorCode.MISSING_ACCESS_TOKEN);
    }
    const token = header.slice(BEARER_PREFIX.length).trim();
    try {
      const payload = await this.jwt.verifyAsync<{ sub: string }>(token);
      (req as Request & { userId?: string }).userId = payload.sub;
      return true;
    } catch {
      throw new DomainError(AuthErrorCode.INVALID_ACCESS_TOKEN);
    }
  }
}
