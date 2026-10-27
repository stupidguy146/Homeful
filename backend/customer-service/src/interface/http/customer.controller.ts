import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { CustomerUseCases } from '../../application/use-case/customer.use-cases';
import {
  CreateProfileRequest,
  UpdateProfileRequest,
} from './request/customer.requests';
import { CustomerPresenter } from './customer.presenter';
import { DomainError, CustomerErrorCode } from '../../shared/errors';
import { SSO_ID_HEADER } from '../../shared/constants';

function requireSsoId(ssoId?: string): string {
  if (!ssoId) {
    throw new DomainError(CustomerErrorCode.MISSING_SSO_ID);
  }
  return ssoId;
}

/**
 * Inbound adapter (Hexagonal): HTTP controller for customer profiles,
 * served under the global 'customer' prefix.
 *
 * Routes:
 *   GET  /customer/me            — current user's profile (x-sso-id header)
 *   PATCH /customer/me           — update current user's profile
 *   POST /customer               — provision a profile (called by auth-service)
 *   GET  /customer/:username     — resolve username → profile (auth login)
 *
 * NOTE: `me` is declared before `:username` so the literal route wins.
 */
@Controller()
export class CustomerController {
  constructor(private readonly customers: CustomerUseCases) {}

  @Get('me')
  async getMe(@Headers(SSO_ID_HEADER) ssoId: string) {
    const p = await this.customers.getMyProfile(requireSsoId(ssoId));
    return CustomerPresenter.profile(p);
  }

  @Patch('me')
  async updateMe(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Body() body: UpdateProfileRequest,
  ) {
    const p = await this.customers.updateMyProfile(requireSsoId(ssoId), body);
    return CustomerPresenter.profile(p);
  }

  @Post()
  @HttpCode(201)
  async create(@Body() body: CreateProfileRequest) {
    const p = await this.customers.createProfile(body);
    return CustomerPresenter.profile(p);
  }

  @Get(':username')
  async getByUsername(@Param('username') username: string) {
    const p = await this.customers.getByUsername(username);
    return CustomerPresenter.profile(p);
  }
}
