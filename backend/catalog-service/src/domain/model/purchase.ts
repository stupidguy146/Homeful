/**
 * Purchase — a single buying event for a product. Monthly summaries and the
 * consumption-cycle statistics are derived from these records. Pure TS.
 */
export interface PurchaseProps {
  id?: number;
  purchaseId: string;
  productId: string;
  ssoId: string;
  quantity: number;
  price: number; // per unit
  buyer: string | null;
  store: string | null;
  purchasedAt: string; // yyyy-mm-dd
  createdAt: Date;
}

export class Purchase {
  readonly id?: number;
  readonly purchaseId: string;
  readonly productId: string;
  readonly ssoId: string;
  quantity: number;
  price: number;
  buyer: string | null;
  store: string | null;
  purchasedAt: string;
  readonly createdAt: Date;

  constructor(p: PurchaseProps) {
    this.id = p.id;
    this.purchaseId = p.purchaseId;
    this.productId = p.productId;
    this.ssoId = p.ssoId;
    this.quantity = p.quantity;
    this.price = p.price;
    this.buyer = p.buyer;
    this.store = p.store;
    this.purchasedAt = p.purchasedAt;
    this.createdAt = p.createdAt;
  }

  /** total spent for this purchase = price × quantity */
  subtotal(): number {
    return this.price * this.quantity;
  }
}
