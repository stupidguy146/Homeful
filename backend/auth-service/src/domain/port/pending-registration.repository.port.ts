import { PendingRegistration } from '../model/pending-registration';

/**
 * Outbound port for pending-registration persistence (Hexagonal).
 * One row per email; re-registering before completion replaces the row.
 */
export interface PendingRegistrationRepositoryPort {
  upsertByEmail(pending: PendingRegistration): Promise<PendingRegistration>;
  findByEmail(email: string): Promise<PendingRegistration | null>;
  update(pending: PendingRegistration): Promise<PendingRegistration>;
  deleteByEmail(email: string): Promise<void>;
}

export const PENDING_REGISTRATION_REPOSITORY = Symbol(
  'PENDING_REGISTRATION_REPOSITORY',
);
