import { Product } from '../model/product';
import { Category } from '../../shared/categories';

/** Outbound port for product master, scoped by owner (ssoId). */
export interface ProductRepositoryPort {
  create(product: Product): Promise<Product>;
  findAll(ssoId: string, category?: Category): Promise<Product[]>;
  findById(productId: string, ssoId: string): Promise<Product | null>;
  update(product: Product): Promise<Product>;
  delete(productId: string, ssoId: string): Promise<void>;
  count(ssoId: string): Promise<number>;
}

export const PRODUCT_REPOSITORY = Symbol('PRODUCT_REPOSITORY');
