# Design Specification — Room Shopping List

ขั้นตอน **Design** ของ SDLC ครอบคลุม architecture, data model, API contract และ OOP design

## 1. System Architecture (Microservice — แนวทาง A)

```
                 ┌─────────────────────┐
   Flutter App ──┤    api-gateway      │  (REST, port 3000)
                 │  - รวม routing       │
                 │  - คุยกับ client ที่เดียว│
                 └──────────┬──────────┘
                            │ REST (HTTP)
            ┌───────────────┴────────────────┐
            │                                 │
 ┌──────────▼───────────┐        ┌────────────▼───────────┐
 │  catalog-service      │        │  analytics-service      │
 │  (port 3001)          │◄───────┤  (port 3002)            │
 │  - CRUD เดือน + รายการ │  REST  │  - ยอดรวมเงินรายเดือน     │
 │                       │        │  - รายการใกล้หมด          │
 └──────────┬───────────┘        └────────────┬───────────┘
            │                                 │
 ┌──────────▼───────────┐        ┌────────────▼───────────┐
 │ catalog_db (Postgres) │        │ analytics_db (Postgres) │
 │  port 5433            │        │  port 5434              │
 └──────────────────────┘        └─────────────────────────┘
```

### หลักการสำคัญ
- **Database-per-service**: catalog-service เป็นเจ้าของ catalog_db เท่านั้น; analytics-service เป็นเจ้าของ analytics_db
- **ห้ามอ่าน DB ข้าม service**: analytics-service ดึงข้อมูลรายการจาก catalog-service **ผ่าน REST** แล้วคำนวณ (และอาจ cache/บันทึกผลสรุปใน analytics_db)
- **API Gateway** เป็นประตูเดียวที่ Flutter เรียก ทำ reverse-proxy ไปยัง service ปลายทาง

## 2. Service Responsibilities
| Service | Port | DB | หน้าที่ |
|---------|------|-----|--------|
| api-gateway | 3000 | - | รับ request จาก client, route ไป service ปลายทาง |
| catalog-service | 3001 | catalog_db:5433 | CRUD เดือน (ShoppingMonth) และรายการ (ShoppingItem) |
| analytics-service | 3002 | analytics_db:5434 | คำนวณยอดรวมรายเดือน, รายการใกล้หมด (ดึงข้อมูลจาก catalog ผ่าน REST) |

## 3. Data Model (ER) — catalog_db

```
ShoppingMonth (เดือนซื้อของ)
 ├─ id           UUID (PK)
 ├─ year         int
 ├─ month        int (1-12)
 ├─ note         text (nullable)
 ├─ createdAt    timestamptz
 └─ items        1..* ShoppingItem

ShoppingItem (รายการของ)
 ├─ id           UUID (PK)
 ├─ monthId      UUID (FK -> ShoppingMonth.id)
 ├─ name         varchar
 ├─ quantity     int
 ├─ unitPrice    numeric(12,2)
 ├─ expiryDate   date (nullable)
 └─ createdAt    timestamptz
```

> analytics_db: เฟสแรกเก็บผลสรุปแบบ on-demand (คำนวณสด) จึงยังไม่มีตารางถาวร
> โครงสร้างเผื่ออนาคต: ตาราง `MonthlySummarySnapshot` สำหรับ cache ผลลัพธ์

## 4. API Contract

ทุก endpoint ที่ client ใช้ จะเรียกผ่าน Gateway (base: `http://localhost:3000`)

### Catalog (ผ่าน gateway prefix `/api/catalog`)
| Method | Path | คำอธิบาย |
|--------|------|----------|
| POST | `/months` | สร้างเดือน `{ year, month, note? }` |
| GET | `/months` | รายการเดือนทั้งหมด |
| GET | `/months/:id` | เดือนเดียว (รวม items) |
| PATCH | `/months/:id` | แก้ไขเดือน |
| DELETE | `/months/:id` | ลบเดือน (cascade items) |
| POST | `/months/:id/items` | เพิ่มรายการ `{ name, quantity, unitPrice, expiryDate? }` |
| GET | `/months/:id/items` | รายการของในเดือน |
| PATCH | `/items/:itemId` | แก้ไขรายการ |
| DELETE | `/items/:itemId` | ลบรายการ |

### Analytics (ผ่าน gateway prefix `/api/analytics`)
| Method | Path | คำอธิบาย |
|--------|------|----------|
| GET | `/months/:id/summary` | ยอดรวมเงินของเดือน `{ totalAmount, totalItems, totalQuantity }` |
| GET | `/summary` | สรุปยอดรวมทุกเดือน |
| GET | `/expiring-soon?days=7` | รายการใกล้หมดภายใน N วัน |

## 5. OOP Design — Clean Architecture + Hexagonal (Ports & Adapters) (NFR-04)

แต่ละ service (ที่มี business logic) จัดโครงเป็น 4 ชั้นตามหลัก Clean Architecture
โดยใช้ Hexagonal (Ports & Adapters) ให้ domain เป็นแกนกลางที่ไม่ผูกกับ framework

### 5.1 Dependency Rule
ทิศทาง dependency ชี้ "เข้าด้านใน" เสมอ:

```
   interface (HTTP)  ─┐
                      ├─►  application (use cases)  ─►  domain (core)
   infrastructure ───┘                                      ▲
   (DB adapter)  ─────────── implements ports ──────────────┘
```

- **domain** ไม่ import อะไรจาก NestJS / TypeORM / layer นอกเลย (pure TypeScript)
- layer นอกพึ่งพา layer ในผ่าน **interface (port)** ไม่ใช่ concrete class

### 5.2 โครงสร้างโฟลเดอร์ (ต่อ service)
```
src/
├─ domain/                         # ชั้นในสุด (Enterprise Business Rules)
│  ├─ model/
│  │  ├─ shopping-month.ts         # pure domain class + behavior (totalAmount)
│  │  └─ shopping-item.ts          # pure domain class + behavior (subtotal, daysUntilExpiry)
│  └─ port/
│     └─ month.repository.port.ts  # interface (outbound port)
│
├─ application/                    # Use Cases (Application Business Rules)
│  ├─ dto/                         # input/output DTO ของ use case
│  └─ use-case/
│     ├─ create-month.use-case.ts
│     ├─ list-months.use-case.ts
│     ├─ get-month.use-case.ts
│     ├─ update-month.use-case.ts
│     ├─ delete-month.use-case.ts
│     ├─ add-item.use-case.ts
│     ├─ update-item.use-case.ts
│     └─ delete-item.use-case.ts
│
├─ infrastructure/                 # Adapters ขาออก (Frameworks & Drivers)
│  ├─ persistence/
│  │  ├─ orm/
│  │  │  ├─ month.orm-entity.ts     # TypeORM entity (แยกจาก domain model)
│  │  │  └─ item.orm-entity.ts
│  │  ├─ mapper/
│  │  │  └─ month.mapper.ts         # map ORM entity <-> domain model
│  │  └─ typeorm-month.repository.ts  # implements MonthRepositoryPort
│  └─ config/
│     └─ typeorm.config.ts
│
└─ interface/                      # Adapters ขาเข้า (Interface Adapters)
   └─ http/
      ├─ month.controller.ts        # NestJS controller
      ├─ item.controller.ts
      └─ request/                   # HTTP request DTO + class-validator
```

### 5.3 Ports & Adapters ต่อ service
| Service | Inbound adapter | Outbound port | Outbound adapter |
|---------|-----------------|---------------|------------------|
| catalog | HTTP controller | `MonthRepositoryPort` | `TypeOrmMonthRepository` (→ catalog_db) |
| analytics | HTTP controller | `CatalogPort` | `HttpCatalogClient` (→ REST ไป catalog-service) |
| api-gateway | HTTP controller | - | proxy adapter ไป service ปลายทาง (ชั้นบาง, ไม่มี domain) |

### 5.4 OOP เน้นอะไร
- **Encapsulation**: domain model ถือ state + business behavior (`subtotal()`, `totalAmount()`, `daysUntilExpiry()`)
- **Dependency Inversion**: use case ขึ้นกับ port (interface) ไม่ใช่ concrete repository; NestJS DI inject adapter จริงตอน runtime ผ่าน token
- **Separation of concerns**: ORM entity (persistence) แยกจาก domain model (business) ด้วย mapper
- **Testability**: use case เทสได้โดย mock port โดยไม่ต้องมี DB จริง

## 6. Deployment
- ทุก service เป็น container แยก + DB แยก container ผ่าน `docker-compose.yml`
- Flutter เรียก `http://localhost:3000` (gateway)

## 7. การ map ความต้องการ → การออกแบบ
| Requirement | รองรับด้วย |
|-------------|-----------|
| FR-01, FR-02, FR-03 | catalog-service CRUD |
| FR-04 | analytics-service `/summary` |
| FR-05 | analytics-service `/expiring-soon` |
| NFR-01, NFR-02 | 3 services + 2 DB แยก |
| NFR-03 | api-gateway + REST |
| NFR-04 | Clean Architecture + Hexagonal (domain/application/infrastructure/interface + ports & adapters) |
| NFR-05 | docker-compose |
