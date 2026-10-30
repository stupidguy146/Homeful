import { ItemView } from '../model/item-view';

/** Lightweight product master view fetched from catalog over REST. */
export interface ProductView {
  productId: string;
  name: string;
  category: string;
}

/** Lightweight purchase view fetched from catalog over REST. */
export interface PurchaseView {
  purchaseId: string;
  productId: string;
  quantity: number;
  price: number;
  subtotal: number;
  buyer: string | null;
  store: string | null;
  purchasedAt: string; // yyyy-mm-dd
}

/**
 * Outbound port: analytics obtains data from catalog-service over REST.
 * Concrete implementation (REST) lives in infrastructure.
 */
export interface CatalogPort {
  getAllItems(ssoId: string): Promise<ItemView[]>;
  getProducts(ssoId: string): Promise<ProductView[]>;
  getPurchasesByMonth(ssoId: string, month: string): Promise<PurchaseView[]>;
}

export const CATALOG_PORT = Symbol('CATALOG_PORT');
