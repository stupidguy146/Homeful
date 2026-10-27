import { ItemView } from '../model/item-view';

/**
 * Outbound port: analytics obtains household items from catalog-service.
 * Concrete implementation (REST) lives in infrastructure.
 */
export interface CatalogPort {
  getAllItems(ssoId: string): Promise<ItemView[]>;
}

export const CATALOG_PORT = Symbol('CATALOG_PORT');
