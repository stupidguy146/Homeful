import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosInstance } from 'axios';
import { CatalogPort, ProductView, PurchaseView } from '../../domain/port/catalog.port';
import { ItemView } from '../../domain/model/item-view';
import { SSO_ID_HEADER } from '../../shared/constants';

/**
 * Outbound adapter: fetches household items from catalog-service over REST.
 * Respects database-per-service (no cross-service DB access).
 */
@Injectable()
export class CatalogHttpAdapter implements CatalogPort {
  private readonly logger = new Logger(CatalogHttpAdapter.name);
  private readonly http: AxiosInstance;

  constructor(config: ConfigService) {
    const baseURL = config.get<string>(
      'CATALOG_SERVICE_URL',
      'http://localhost:3001',
    );
    this.http = axios.create({ baseURL, timeout: 6000 });
  }

  async getAllItems(ssoId: string): Promise<ItemView[]> {
    try {
      const { data } = await this.http.get('/catalog/items', {
        headers: { [SSO_ID_HEADER]: ssoId },
      });
      return (data as any[]).map(
        (i) =>
          new ItemView(
            i.itemId,
            i.name,
            i.category,
            Number(i.quantity ?? 0),
            Number(i.price ?? 0),
            i.purchaseDate ?? null,
            i.expiryDate ?? null,
            i.imageBase64 ?? null,
            Boolean(i.notifyRecurring ?? false),
          ),
      );
    } catch (err: any) {
      this.logger.error(`catalog call failed: ${err?.message}`);
      throw err;
    }
  }

  async getProducts(ssoId: string): Promise<ProductView[]> {
    try {
      const { data } = await this.http.get('/catalog/products', {
        headers: { [SSO_ID_HEADER]: ssoId },
      });
      return (data as any[]).map((p) => ({
        productId: p.productId,
        name: p.name,
        category: p.category,
      }));
    } catch (err: any) {
      this.logger.error(`catalog products call failed: ${err?.message}`);
      throw err;
    }
  }

  async getPurchasesByMonth(
    ssoId: string,
    month: string,
  ): Promise<PurchaseView[]> {
    try {
      const { data } = await this.http.get('/catalog/purchases', {
        headers: { [SSO_ID_HEADER]: ssoId },
        params: { month },
      });
      const items = (data?.items as any[]) ?? [];
      return items.map((p) => ({
        purchaseId: p.purchaseId,
        productId: p.productId,
        quantity: Number(p.quantity ?? 0),
        price: Number(p.price ?? 0),
        subtotal: Number(p.subtotal ?? 0),
        buyer: p.buyer ?? null,
        store: p.store ?? null,
        purchasedAt: p.purchasedAt,
      }));
    } catch (err: any) {
      this.logger.error(`catalog purchases call failed: ${err?.message}`);
      throw err;
    }
  }
}
