import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { ProxyService } from '../proxy/proxy.service';
import { JwtVerifyGuard } from './jwt-verify.guard';

/**
 * Gateway controller: exposes auth endpoints under /api/auth and forwards
 * them to auth-service. register/login/refresh are public; me is protected.
 */
@Controller('api/auth')
export class AuthProxyController {
  constructor(private readonly proxy: ProxyService) {}

  @Post('register')
  register(@Body() body: unknown) {
    return this.proxy.forwardToAuth('POST', '/auth/register', body);
  }

  @Post('login')
  @HttpCode(200)
  login(@Body() body: unknown) {
    return this.proxy.forwardToAuth('POST', '/auth/login', body);
  }

  @Post('refresh')
  @HttpCode(200)
  refresh(@Body() body: unknown) {
    return this.proxy.forwardToAuth('POST', '/auth/refresh', body);
  }

  @Get('me')
  @UseGuards(JwtVerifyGuard)
  me(@Req() req: Request & { ssoId: string }) {
    // forward the verified identity to auth-service as a trusted header
    return this.proxy.forwardToAuth('GET', '/auth/me', undefined, undefined, {
      authorization: req.headers['authorization'] as string,
    });
  }

  @Post('change-password')
  @HttpCode(200)
  @UseGuards(JwtVerifyGuard)
  changePassword(@Req() req: Request, @Body() body: unknown) {
    return this.proxy.forwardToAuth(
      'POST',
      '/auth/change-password',
      body,
      undefined,
      { authorization: req.headers['authorization'] as string },
    );
  }

  @Get('verify-email')
  @HttpCode(200)
  verifyEmail(@Query('token') token: string) {
    return this.proxy.forwardToAuth('GET', '/auth/verify-email', undefined, {
      token,
    });
  }

  @Post('resend-verification')
  @HttpCode(200)
  @UseGuards(JwtVerifyGuard)
  resendVerification(@Req() req: Request) {
    return this.proxy.forwardToAuth(
      'POST',
      '/auth/resend-verification',
      undefined,
      undefined,
      { authorization: req.headers['authorization'] as string },
    );
  }

  @Post('forgot-password')
  @HttpCode(200)
  forgotPassword(@Body() body: unknown) {
    return this.proxy.forwardToAuth('POST', '/auth/forgot-password', body);
  }

  @Post('reset-password')
  @HttpCode(200)
  resetPassword(@Body() body: unknown) {
    return this.proxy.forwardToAuth('POST', '/auth/reset-password', body);
  }
}
