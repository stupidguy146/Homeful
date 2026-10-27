import { Inject, Injectable } from '@nestjs/common';
import {
  CUSTOMER_REPOSITORY,
  CustomerRepositoryPort,
} from '../../domain/port/customer.repository.port';
import { CustomerProfile } from '../../domain/model/customer-profile';
import { CreateProfileCommand, UpdateProfileCommand } from '../dto/commands';
import { DomainError, CustomerErrorCode } from '../../shared/errors';

/**
 * Application use-cases for customer profiles.
 * - createProfile: called by auth-service at registration (service-to-service)
 * - findByUsername: lets auth resolve a username → profile (login identifier)
 * - getMyProfile / updateMyProfile: the signed-in user's own profile
 */
@Injectable()
export class CustomerUseCases {
  constructor(
    @Inject(CUSTOMER_REPOSITORY)
    private readonly repo: CustomerRepositoryPort,
  ) {}

  /** Provision a profile for a freshly registered identity. */
  async createProfile(cmd: CreateProfileCommand): Promise<CustomerProfile> {
    const existingUsername = await this.repo.findByUsername(cmd.username);
    if (existingUsername) {
      throw new DomainError(CustomerErrorCode.USERNAME_TAKEN);
    }
    const profile = CustomerProfile.create(cmd);
    return this.repo.save(profile);
  }

  /** Resolve a username to its profile (used by auth for username login). */
  async getByUsername(username: string): Promise<CustomerProfile> {
    const profile = await this.repo.findByUsername(username);
    if (!profile) {
      throw new DomainError(CustomerErrorCode.PROFILE_NOT_FOUND);
    }
    return profile;
  }

  async getMyProfile(ssoId: string): Promise<CustomerProfile> {
    const existing = await this.repo.findBySsoId(ssoId);
    if (existing) return existing;
    // fallback: profile not provisioned yet (e.g. legacy identity)
    const created = CustomerProfile.createDefault(ssoId);
    return this.repo.save(created);
  }

  async updateMyProfile(
    ssoId: string,
    cmd: UpdateProfileCommand,
  ): Promise<CustomerProfile> {
    const profile = await this.getMyProfile(ssoId);
    // if changing username, ensure it is not taken by someone else
    if (cmd.username !== undefined && cmd.username !== profile.username) {
      const taken = await this.repo.findByUsername(cmd.username);
      if (taken && taken.ssoId !== ssoId) {
        throw new DomainError(CustomerErrorCode.USERNAME_TAKEN);
      }
    }
    profile.applyUpdate(cmd);
    return this.repo.save(profile);
  }
}
