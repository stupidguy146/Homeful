# Design — Product Master + Purchases + Wishlist + Smart Reminders

Redesign ที่แยกข้อมูลเป็น **Product (master)** และ **Purchase (รายครั้ง)** พร้อม
Wishlist, หน้า "ต้องซื้อ" แบบแบ่ง section, และการแจ้งเตือนที่คำนวณจากสถิติการซื้อ.

> สถานะ: **DESIGN — รอรีวิว** ก่อนลงมือ implement.
> เอกสารนี้แทนที่แนวคิด "item เดี่ยว" เดิม และ dead flag `notifyRecurring` + `recurringDays`
> จะถูกย้าย/ตีความใหม่ตามนี้.

---

## 1. แนวคิดหลัก (2 ชั้น)

```
Product (master)                 Purchase (รายครั้ง)
"เรามีของอะไรบ้าง"        1 ──< many   "เดือนนี้ซื้ออะไรมาบ้าง"
- ชื่อ/หมวด/ขนาด/หน่วย/รูป              - จำนวน, ราคา/หน่วย, ยอดรวม
- flag ซื้อประจำ (isRecurring)          - ผู้ซื้อ, ร้าน
- สถานะปัจจุบัน (in_stock/low/out)      - วันที่ซื้อ (purchasedAt)
- recurringDaysManual (fallback)
```

- **Product** = ทะเบียนสินค้าถาวรของ account (เพิ่มครั้งแรกเยอะ แล้วใช้ยาว)
- **Purchase** = event การซื้อแต่ละครั้ง ผูกกับ product → ใช้ทำสรุปรายเดือน + สถิติรอบ
- **ขนาด/หน่วยอยู่ที่ Product** (ข้อ B): ถ้าขนาดเปลี่ยน = คนละพฤติกรรม ไม่นับเป็นซื้อประจำ
- **flag ซื้อประจำอยู่ที่ Product ที่เดียว** (ข้อจากโจทย์)

---

## 2. Data Model (catalog-service, catalog_db)

### 2.1 products
| field | type | note |
|-------|------|------|
| id | serial PK | internal |
| productId | uuid | public |
| ssoId | uuid | owner |
| name | varchar | |
| category | varchar | enum เดิม |
| size | varchar null | ขนาด (เช่น "1.5") — อยู่ที่ master |
| unit | varchar null | หน่วยขนาด (เช่น "ลิตร") |
| unitLabel | varchar null | หน่วยนับ (เช่น "ขวด") |
| imageBase64 | text null | |
| isRecurring | boolean | flag ซื้อประจำ (ที่เดียว) |
| recurringDaysManual | int null | รอบที่ user กรอก (fallback ข้อ A) |
| expiryDate | date null | วันหมดอายุ (ของ non-recurring เช่น ยา/ของสด) — ยังเตือนจากค่านี้ |
| status | varchar | `in_stock` \| `low` \| `out` (user กดเปลี่ยน) |
| createdAt | timestamptz | |

### 2.2 purchases
| field | type | note |
|-------|------|------|
| id | serial PK | |
| purchaseId | uuid | public |
| productId | uuid | FK → products.productId |
| ssoId | uuid | owner (denormalized เพื่อ query เร็ว) |
| quantity | int | จำนวนที่ซื้อครั้งนี้ |
| price | numeric | ราคา/หน่วย |
| buyer | varchar null | ผู้ซื้อ |
| store | varchar null | ร้าน |
| purchasedAt | date | **วันที่ซื้อ** (สำคัญต่อสถิติ) |
| createdAt | timestamptz | |

### 2.3 wishlist
| field | type | note |
|-------|------|------|
| id | serial PK | |
| wishId | uuid | public |
| ssoId | uuid | owner |
| name | varchar | |
| category | varchar null | |
| note | varchar null | |
| createdAt | timestamptz | |

> **stock ปัจจุบัน (ข้อ C)**: ไม่ track ปริมาณจริง. `products.status` เปลี่ยนด้วยปุ่ม
> user กด — **"ใกล้หมด" → low**, **"หมดแล้ว" → out**. ของที่ซื้อใหม่ (purchase) รีเซ็ต
> status → `in_stock`.

---

## 3. สถิติ & การคำนวณวันหมด (Phase 3)

สำหรับ product ที่ `isRecurring = true`:
- ดึง `purchasedAt` ของ purchases เรียงเวลา
- **avgCycleDays** = ค่าเฉลี่ยช่วงห่างระหว่างครั้งที่ซื้อติดกัน (ต้องมี ≥2 purchases)
  - ตัวอย่าง ซื้อ 1 ต.ค., 8 ต.ค., 16 ต.ค. → ช่วง 7,8 → เฉลี่ย 7.5 วัน
- **nextDueDate** = วันซื้อล่าสุด + avgCycleDays
- ถ้ามี purchase ครั้งเดียว (ยังคำนวณไม่ได้) → **fallback `recurringDaysManual`** (ข้อ A)
- ถ้าไม่มีทั้งคู่ → ไม่เตือน

### การแจ้งเตือน (period 7 → 3 → 1 → หมด)
เทียบ `nextDueDate` กับวันนี้ → daysUntilDue:
- 7 วัน: "ใกล้ครบรอบ — เริ่มวางแผนซื้อ"
- 3 วัน: "อีก 3 วันน่าจะหมด"
- 1 วัน: "พรุ่งนี้น่าจะหมด"
- ≤0 หรือ status=out: "น่าจะหมดแล้ว — ซื้ออีกไหม?"

### เตือนก่อนสิ้นเดือน
- วันที่ 25–สิ้นเดือน เตือน 1 ครั้ง: "อย่าลืมเช็คของประจำเดือน" → เปิดหน้าเช็ค
  (user ไล่กด สถานะ ใกล้หมด/หมด)

---

## 4. API (ผ่าน gateway /api/catalog)

### Products (master)
| Method | Path | ใช้ทำ |
|--------|------|-------|
| POST | /products | เพิ่ม product ใหม่ (+ purchase แรก optional) |
| GET | /products | list master ทั้งหมด (+ สถานะ + nextDueDate คำนวณ) |
| GET | /products/:id | product เดียว + ประวัติซื้อ |
| PATCH | /products/:id | แก้ master (ชื่อ/ขนาด/isRecurring/recurringDaysManual) |
| PATCH | /products/:id/status | เปลี่ยนสถานะ (low/out/in_stock) ← ปุ่ม ใกล้หมด/หมดแล้ว |
| DELETE | /products/:id | ลบ |

### Purchases
| Method | Path | ใช้ทำ |
|--------|------|-------|
| POST | /products/:id/purchases | บันทึกการซื้อ (จาก "ซื้อ" ในหน้า to-buy หรือเพิ่มเอง) |
| GET | /purchases?month=YYYY-MM | รายการซื้อของเดือน (สรุปรายเดือน) |

### Wishlist
| Method | Path | |
|--------|------|-|
| GET/POST/DELETE | /wishlist | CRUD wishlist |

### Analytics (analytics-service, ปรับใหม่)
| Method | Path | |
|--------|------|-|
| GET | /summary?month= | สรุปรายเดือนจาก purchases (ยอด/จำนวน/แยกหมวด/ผู้ซื้อ) |
| GET | /to-buy | รวม out + low + wishlist แบ่ง section |
| GET | /reminders | product recurring ที่ถึง period เตือน (คำนวณ nextDueDate) |

---

## 5. Frontend (หน้าหลัก)

- **Products (master list)**: ดูของทั้งหมดที่มี + สถานะ + badge "ซื้อประจำ"
- **เพิ่มสินค้า**: สร้าง product (+ซื้อครั้งแรก); ช่อง isRecurring + recurringDaysManual (เฉพาะเมื่อ recurring)
- **สรุปรายเดือน (Home/Analytics)**: เดือนนี้ซื้ออะไร กี่ชิ้น ยอดรวม ใครซื้อ
- **ต้องซื้อ (to-buy)** แบ่ง section: 🔴 หมด / 🟡 ใกล้หมด / ⭐ wishlist
  - แก้ qty ได้ → ติ๊ก + "ซื้อ" → POST purchase (purchasedAt = วันนี้) + reset status in_stock
- **Product detail**: ข้อมูล master + ประวัติซื้อ + ปุ่ม "ใกล้หมด"/"หมดแล้ว"
- **Wishlist**: เพิ่ม/ลบของอยากได้
- **Notifications**: reminders จากสถิติ (period 7/3/1/หมด) + เตือนสิ้นเดือน

---

## 6. Phased Delivery

### Phase 1 — Product master + Purchase + สรุปรายเดือน
- catalog: ตาราง products + purchases, API products CRUD + purchases POST/GET
- migrate: item เดิม → product (+ purchase แรกจาก purchaseDate/price/qty)
- analytics summary ดึงจาก purchases (รายเดือน)
- frontend: เพิ่มสินค้า=สร้าง product, หน้า master list, สรุปรายเดือน

### Phase 2 — Wishlist + หน้า to-buy แบบ section + ปุ่มซื้อ
- catalog: wishlist CRUD, PATCH status, endpoint to-buy รวม
- frontend: หน้า to-buy แบ่ง section + แก้ qty + ปุ่มซื้อ (สร้าง purchase), wishlist, ปุ่ม ใกล้หมด/หมดแล้ว

### Phase 3 — สถิติคำนวณวันหมด + reminders
- analytics: คำนวณ avgCycleDays + nextDueDate, endpoint reminders
- noti: period 7/3/1/หมด จาก nextDueDate (fallback recurringDaysManual), เตือนสิ้นเดือน

---

## 7. Migration (ข้อมูลเดิม)
- items ที่มีอยู่ → สร้าง product ต่อ 1 แถว (ชื่อ/หมวด/ขนาด/รูป/isRecurring=notifyRecurring/recurringDaysManual=recurringDays)
- ถ้า item มี purchaseDate/price/quantity → สร้าง purchase แรกให้ product นั้น
- expiryDate เดิม: ของที่ไม่ recurring เก็บเป็น field เสริมบน product (optional) หรือ drop ตามที่ตกลงภายหลัง

---

## 9. สถานะการทำ (resume note)

**Phase 1 — เสร็จ 10/10** ✅ (ณ session ล่าสุด):

Backend ครบ (build ผ่านทุก service):
- ✅ catalog-service: domain `Product`/`Purchase` + ports, ORM (`products`/`purchases`)
  + mappers + adapters, `ProductUseCases` (product CRUD + status + purchase
  create/list-by-month), controllers (`POST/GET/PATCH/DELETE /products`,
  `PATCH /products/:id/status`, `GET /products/:id/history`,
  `POST /products/:id/purchases`, `GET /purchases?month=`), validators,
  presenter, และ `ItemToProductMigration` (รันตอน boot ผ่าน OnModuleInit,
  idempotent ด้วยคอลัมน์ `products.sourceItemId`).
- ✅ api-gateway: proxy `/api/catalog/products*` + `/api/catalog/purchases`
  + `/api/analytics/summary-month`.
- ✅ analytics-service: `summaryByMonth(ssoId, month)` → `{ month, grandTotal,
  totalPurchases, totalQty, byCategory[], byBuyer[] }` (ดึง products +
  purchases จาก catalog ผ่าน REST). endpoint เดิม summary/expiring-soon ยังอยู่.

Frontend:
- ✅ Task 8: `lib/models/product.dart`, `lib/models/purchase.dart`
  (+`MonthlySummary`), และ api_service methods: `getProducts/getProduct/
  createProduct/updateProduct/updateProductStatus/deleteProduct/
  getProductHistory/createPurchase/getPurchasesByMonth/getMonthlySummary`.
  (`flutter analyze` สะอาด)

**เสร็จแล้ว (session ล่าสุด):**
- ✅ Task 9 (frontend UI, **เพิ่มหน้าใหม่ ไม่ลบของเดิม**):
  - `lib/screens/product_master_screen.dart` — รายการ product master + badge
    ซื้อประจำ + สถานะ (มีของ/ใกล้หมด/หมดแล้ว) + ค้นหา/กรองหมวด + ปัดซ้ายเพื่อลบ
    + FAB → เพิ่มสินค้า
  - `lib/screens/add_product_screen.dart` — สร้าง product + ส่วน "ซื้อครั้งแรก"
    (initialPurchase) เปิด/ปิดได้ + isRecurring + recurringDaysManual
  - `lib/screens/monthly_summary_screen.dart` — `getMonthlySummary(month)` +
    `getPurchasesByMonth` + เลือกเดือนได้ (prev/next) + การ์ดสรุป + แยกหมวด/ผู้ซื้อ
  - wire เข้า `lib/screens/main_shell.dart` (เพิ่ม 2 เมนู: คลังสินค้า, สรุปรายเดือน
    — 5 แท็บเดิมอยู่ครบ)
  - i18n strings ใหม่ใน `lib/i18n/app_strings.dart` (`_t(th,en)`)
- ✅ Task 10 (verify):
  - `flutter analyze` สะอาด, `flutter test` ผ่าน (21 tests), `flutter build web` สำเร็จ
  - rebuild containers (`docker compose up -d --build catalog-service
    analytics-service api-gateway`) — 9 containers up/healthy
  - migration ยืนยันจาก log: `migrated 6 legacy item(s) → product(s)`
  - end-to-end ผ่าน gateway (token จริง): `POST /products` (+initialPurchase) →
    `GET /products` / `GET /purchases?month` / `GET /analytics/summary-month`
    คืน JSON ตรงกับ model ฝั่ง frontend
  - รัน iOS simulator (iPhone 17)

**ของเดิม (items/home/to-buy/notification/recurringDays/ปุ่มหมดแล้ว) ยังอยู่ครบ
ไม่แตะ** — แอปใช้งานได้ปกติระหว่าง migrate.
