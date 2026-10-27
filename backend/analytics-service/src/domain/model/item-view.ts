/**
 * Lightweight view of a household item as seen by analytics
 * (fetched from catalog-service over REST). Pure data.
 */
export class ItemView {
  constructor(
    public readonly itemId: string,
    public readonly name: string,
    public readonly category: string,
    public readonly quantity: number,
    public readonly price: number,
    public readonly purchaseDate: string | null, // yyyy-mm-dd
    public readonly expiryDate: string | null, // yyyy-mm-dd
  ) {}

  subtotal(): number {
    return this.price * this.quantity;
  }

  daysUntilExpiry(now = new Date()): number | null {
    if (!this.expiryDate) return null;
    const exp = new Date(this.expiryDate);
    const base = new Date(now.toISOString().slice(0, 10));
    return Math.round((exp.getTime() - base.getTime()) / 86400000);
  }
}
