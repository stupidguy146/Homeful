import {
  Body,
  Controller,
  Get,
  Patch,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { ProxyService } from '../proxy/proxy.service';
import { JwtVerifyGuard } from './jwt-verify.guard';
import { SSO_ID_HEADER } from '../shared/constants';

/**
 * Gateway controller: exposes customer-profile endpoints under /api/customer
 * and forwards them to customer-service. Protected by JWT; the verified user
 * id is forwarded as `x-sso-id` so the service scopes to the caller.
 */
@Controller('api/customer')
@UseGuards(JwtVerifyGuard)
export class CustomerProxyController {
  constructor(private readonly proxy: ProxyService) {}

  private sso(req: Request): Record<string, string> {
    return { [SSO_ID_HEADER]: (req as Request & { ssoId: string }).ssoId };
  }

  @Get('me')
  getMe(@Req() req: Request) {
    return this.proxy.forwardToCustomer(
      'GET',
      '/customer/me',
      undefined,
      undefined,
      this.sso(req),
    );
  }

  @Patch('me')
  updateMe(@Req() req: Request, @Body() body: unknown) {
    return this.proxy.forwardToCustomer(
      'PATCH',
      '/customer/me',
      body,
      undefined,
      this.sso(req),
    );
  }
}
