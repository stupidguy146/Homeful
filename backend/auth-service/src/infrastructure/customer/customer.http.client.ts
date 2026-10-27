import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosInstance } from 'axios';
import { CustomerClientPort } from '../../domain/port/customer.client.port';
import { DomainError, AuthErrorCode } from '../../shared/errors';

/**
 * Outbound adapter: calls customer-service over REST.
 * Base URL from CUSTOMER_SERVICE_URL (defaults to local dev port).
 */
@Injectable()
export class CustomerHttpClient implements CustomerClientPort {
  private readonly http: AxiosInstance;

  constructor(config: ConfigService) {
    this.http = axios.create({
      baseURL: config.get<string>(
        'CUSTOMER_SERVICE_URL',
        'http://localhost:3004',
      ),
      timeout: 8000,
      validateStatus: () => true,
    });
  }

  async createProfile(params: {
    ssoId: string;
    username: string;
    firstName: string;
    lastName: string;
  }): Promise<void> {
    const res = await this.http.post('/customer', params);
    if (res.status >= 400) {
      // relay a meaningful code when the username is taken
      const code = res.data?.code;
      if (code === 'USERNAME_TAKEN') {
        throw new DomainError(AuthErrorCode.USERNAME_TAKEN);
      }
      throw new DomainError(AuthErrorCode.PROFILE_PROVISION_FAILED);
    }
  }

  async findSsoIdByUsername(username: string): Promise<string | null> {
    const res = await this.http.get(
      `/customer/${encodeURIComponent(username)}`,
    );
    if (res.status === 404) return null;
    if (res.status >= 400) {
      throw new DomainError(AuthErrorCode.PROFILE_PROVISION_FAILED);
    }
    return (res.data?.ssoId as string) ?? null;
  }
}
