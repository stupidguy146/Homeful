import { Purchase } from '../../../domain/model/purchase';
import { PurchaseRecord } from '../orm/purchase.persistence';

export class PurchaseMapper {
  static toRecord(d: Purchase): PurchaseRecord {
    const r = new PurchaseRecord();
    if (d.id !== undefined) r.id = d.id;
    r.purchaseId = d.purchaseId;
    r.productId = d.productId;
    r.ssoId = d.ssoId;
    r.quantity = d.quantity;
    r.price = d.price.toFixed(2);
    r.buyer = d.buyer;
    r.store = d.store;
    r.purchasedAt = d.purchasedAt;
    r.createdAt = d.createdAt;
    return r;
  }

  static toDomain(r: PurchaseRecord): Purchase {
    return new Purchase({
      id: r.id,
      purchaseId: r.purchaseId,
      productId: r.productId,
      ssoId: r.ssoId,
      quantity: r.quantity,
      price: parseFloat(r.price ?? '0'),
      buyer: r.buyer,
      store: r.store,
      purchasedAt:
        typeof r.purchasedAt === 'string'
          ? r.purchasedAt.slice(0, 10)
          : r.purchasedAt,
      createdAt: r.createdAt,
    });
  }
}
