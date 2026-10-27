import {
  CanActivate,
  ExecutionContext,
  Injectable,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { DomainError, GatewayErrorCode } from '../shared/errors';
import { BEARER_PREFIX } from '../shared/constants';

/**
 * Gateway guard: verifies the Bearer access token locally (shared JWT_SECRET
 * with auth-service) and attaches the user id to the request. Downstream
 * controllers forward it as the `x-sso-id` header so services can scope data.
 */
@Injectable()
export class JwtVerifyGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<Request>();
    const header = req.headers['authorization'];
    if (!header || !header.startsWith(BEARER_PREFIX)) {
      throw new DomainError(GatewayErrorCode.MISSING_ACCESS_TOKEN);
    }
    const token = header.slice(BEARER_PREFIX.length).trim();
    try {
      const payload = await this.jwt.verifyAsync<{ sub: string }>(token);
      (req as Request & { ssoId?: string }).ssoId = payload.sub;
      return true;
    } catch {
      throw new DomainError(GatewayErrorCode.INVALID_ACCESS_TOKEN);
    }
  }
}
