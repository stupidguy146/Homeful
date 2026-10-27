import { CustomerProfile } from '../model/customer-profile';

/**
 * Outbound port (Hexagonal). Application depends on this interface,
 * not on any concrete DB implementation (Dependency Inversion).
 */
export interface CustomerRepositoryPort {
  findBySsoId(ssoId: string): Promise<CustomerProfile | null>;
  findByUsername(username: string): Promise<CustomerProfile | null>;
  save(profile: CustomerProfile): Promise<CustomerProfile>;
}

/** DI token for the port */
export const CUSTOMER_REPOSITORY = Symbol('CUSTOMER_REPOSITORY');
