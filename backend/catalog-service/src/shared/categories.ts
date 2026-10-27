/** Fixed set of household item categories (enum for this phase). */
export const CATEGORIES = [
  'laundry', // ซักล้าง
  'kitchen', // ห้องครัว
  'bathroom', // ห้องน้ำ
  'food', // อาหารและเครื่องดื่ม
  'personal', // ของใช้ส่วนตัว
  'other', // อื่นๆ
] as const;

export type Category = (typeof CATEGORIES)[number];

export function isCategory(v: unknown): v is Category {
  return typeof v === 'string' && (CATEGORIES as readonly string[]).includes(v);
}
