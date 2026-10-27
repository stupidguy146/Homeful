import { Inject, Injectable } from '@nestjs/common';
import { CATALOG_PORT, CatalogPort } from '../../domain/port/catalog.port';

/**
 * Analytics use cases computed from household items (via CatalogPort).
 * - summary: grand total, spend per month (by purchaseDate), by category
 * - expiringSoon: items expiring within N days
 */
@Injectable()
export class AnalyticsUseCases {
  constructor(
    @Inject(CATALOG_PORT)
    private readonly catalog: CatalogPort,
  ) {}

  async summary(ssoId: string) {
    const items = await this.catalog.getAllItems(ssoId);

    let grandTotal = 0;
    const byMonth = new Map<string, number>(); // 'yyyy-mm' → amount
    const byCategory = new Map<string, number>(); // category → amount

    for (const it of items) {
      const sub = it.subtotal();
      grandTotal += sub;
      byCategory.set(it.category, (byCategory.get(it.category) ?? 0) + sub);
      if (it.purchaseDate) {
        const key = it.purchaseDate.slice(0, 7); // yyyy-mm
        byMonth.set(key, (byMonth.get(key) ?? 0) + sub);
      }
    }

    const months = [...byMonth.entries()]
      .map(([month, amount]) => ({ month, amount }))
      .sort((a, b) => a.month.localeCompare(b.month));
    const categories = [...byCategory.entries()]
      .map(([category, amount]) => ({ category, amount }))
      .sort((a, b) => b.amount - a.amount);

    return {
      grandTotal,
      totalItems: items.length,
      months,
      categories,
    };
  }

  async expiringSoon(days: number, ssoId: string) {
    const items = await this.catalog.getAllItems(ssoId);
    const now = new Date();
    const result = items
      .map((it) => ({ it, d: it.daysUntilExpiry(now) }))
      .filter(({ d }) => d !== null && d <= days)
      .map(({ it, d }) => ({
        itemId: it.itemId,
        name: it.name,
        category: it.category,
        quantity: it.quantity,
        expiryDate: it.expiryDate,
        daysUntilExpiry: d,
      }));
    result.sort((a, b) => (a.daysUntilExpiry ?? 0) - (b.daysUntilExpiry ?? 0));
    return { days, count: result.length, items: result };
  }
}
