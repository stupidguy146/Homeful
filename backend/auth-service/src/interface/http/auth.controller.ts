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
import { AuthUseCases } from '../../application/use-case/auth.use-cases';
import {
  LoginRequest,
  RefreshRequest,
  RegisterRequest,
  ChangePasswordRequest,
  ForgotPasswordRequest,
  ResetPasswordRequest,
} from './request/auth.requests';
import { JwtAuthGuard } from './jwt-auth.guard';

/**
 * Inbound adapter (Hexagonal): HTTP controller for authentication.
 * Routes are served under the global 'auth' prefix (set in main.ts),
 * e.g. POST /auth/register, POST /auth/login.
 */
@Controller()
export class AuthController {
  constructor(private readonly auth: AuthUseCases) {}

  @Post('register')
  register(@Body() body: RegisterRequest) {
    return this.auth.register(body);
  }

  @Post('login')
  @HttpCode(200)
  login(@Body() body: LoginRequest) {
    return this.auth.login(body);
  }

  @Post('refresh')
  @HttpCode(200)
  refresh(@Body() body: RefreshRequest) {
    return this.auth.refresh(body.refreshToken);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@Req() req: Request & { userId: string }) {
    return this.auth.me(req.userId);
  }

  @Post('change-password')
  @HttpCode(200)
  @UseGuards(JwtAuthGuard)
  async changePassword(
    @Req() req: Request & { userId: string },
    @Body() body: ChangePasswordRequest,
  ) {
    await this.auth.changePassword(
      req.userId,
      body.oldPassword,
      body.newPassword,
    );
    return { message: 'password changed' };
  }

  @Get('verify-email')
  @HttpCode(200)
  async verifyEmail(@Query('token') token: string) {
    await this.auth.verifyEmail(token ?? '');
    return { message: 'email verified' };
  }

  @Post('resend-verification')
  @HttpCode(200)
  @UseGuards(JwtAuthGuard)
  async resendVerification(@Req() req: Request & { userId: string }) {
    await this.auth.resendVerification(req.userId);
    return { message: 'verification email sent' };
  }

  @Post('forgot-password')
  @HttpCode(200)
  async forgotPassword(@Body() body: ForgotPasswordRequest) {
    await this.auth.forgotPassword(body.email);
    // always 200 — do not reveal whether the email exists
    return { message: 'if the account exists, a reset email was sent' };
  }

  @Post('reset-password')
  @HttpCode(200)
  async resetPassword(@Body() body: ResetPasswordRequest) {
    await this.auth.resetPassword(body.token, body.newPassword);
    return { message: 'password reset' };
  }
}
