import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosInstance } from 'axios';
import { CatalogPort } from '../../domain/port/catalog.port';
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
          ),
      );
    } catch (err: any) {
      this.logger.error(`catalog call failed: ${err?.message}`);
      throw err;
    }
  }
}
