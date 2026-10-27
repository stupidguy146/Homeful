import { HouseholdItem } from '../model/household-item';
import { Category } from '../../shared/categories';

/** Outbound port (Hexagonal) for household items, scoped by owner (ssoId). */
export interface ItemRepositoryPort {
  create(item: HouseholdItem): Promise<HouseholdItem>;
  findAll(ssoId: string, category?: Category): Promise<HouseholdItem[]>;
  findById(itemId: string, ssoId: string): Promise<HouseholdItem | null>;
  update(item: HouseholdItem): Promise<HouseholdItem>;
  delete(itemId: string, ssoId: string): Promise<void>;
}

export const ITEM_REPOSITORY = Symbol('ITEM_REPOSITORY');
