import { User } from '../model/user';

/**
 * Outbound port (Hexagonal). Application depends on this interface,
 * not on any concrete DB implementation (Dependency Inversion).
 */
export interface UserRepositoryPort {
  create(user: User): Promise<User>;
  findByEmail(email: string): Promise<User | null>;
  findBySsoId(ssoId: string): Promise<User | null>;
  findByVerifyToken(token: string): Promise<User | null>;
  findByResetToken(token: string): Promise<User | null>;
  update(user: User): Promise<User>;
}

/** DI token for the port */
export const USER_REPOSITORY = Symbol('USER_REPOSITORY');
