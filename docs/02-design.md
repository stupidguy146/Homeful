# Design Specification — Checkon (เช็คก่อน)

ขั้นตอน **Design** ของ SDLC ครอบคลุม architecture, data model, API contract และ OOP design

## 1. System Architecture (Microservice)

```
                       ┌─────────────────────┐
     Flutter (Checkon)─┤    api-gateway      │  (REST, port 3000)
                       │  - routing/proxy     │
                       │  - verify JWT        │
                       └──────────┬──────────┘
                                  │ REST (HTTP)
      ┌──────────────┬───────────┼───────────────┬──────────────┐
      │              │           │               │              │
┌─────▼─────┐  ┌─────▼─────┐ ┌───▼────────┐ ┌────▼────────┐
│   auth    │  │ customer  │ │  catalog   │ │ analytics   │
│  (3003)   │─►│  (3004)   │ │  (3001)    │◄│  (3002)     │
│           │  │           │ │            │ │ (ดึง catalog │
│           │  │           │ │            │ │  ผ่าน REST)  │
└─────┬─────┘  └─────┬─────┘ └─────┬──────┘ └─────┬───────┘
      │              │             │              │
 ┌────▼────┐   ┌─────▼─────┐  ┌────▼─────┐  ┌──────▼──────┐
 │ auth_db │   │customer_db│  │catalog_db│  │analytics_db │
 │  5435   │   │   5436    │  │  5433    │  │   5434      │
 └─────────┘   └───────────┘  └──────────┘  └─────────────┘
```

### หลักการสำคัญ
- **Database-per-service**: แต่ละ service เป็นเจ้าของ DB ตัวเอง ห้ามอ่าน DB ข้าม service
- **ความสัมพันธ์ข้าม service ผ่าน REST เท่านั้น**:
  - `auth` เรียก `customer` เพื่อ provision โปรไฟล์ตอนตั้งรหัสผ่าน และ resolve `username → ssoId` ตอนล็อกอิน
  - `analytics` เรียก `catalog` เพื่อดึงรายการสินค้ามาคำนวณสรุป/ของใกล้หมด
- **API Gateway** เป็นประตูเดียวของ client, proxy ไป service ปลายทาง และตรวจ JWT สำหรับ route ที่ต้องล็อกอิน (ส่ง `x-sso-id` ต่อให้ service ปลายทาง)

## 2. Service Responsibilities
| Service | Port | DB | หน้าที่ |
|---------|------|-----|--------|
| api-gateway | 3000 | - | รับ request จาก client, ตรวจ JWT, route ไป service ปลายทาง |
| auth-service | 3003 | auth_db:5435 | สมัคร (pending + OTP), ยืนยัน OTP, ตั้งรหัสผ่าน, ล็อกอิน, refresh, เปลี่ยน/รีเซ็ตรหัสผ่าน |
| customer-service | 3004 | customer_db:5436 | โปรไฟล์ลูกค้า (title/username/ชื่อ/รูป/สถานะ/วันเกิด) |
| catalog-service | 3001 | catalog_db:5433 | CRUD สินค้า (ShoppingItem) |
| analytics-service | 3002 | analytics_db:5434 | สรุปค่าใช้จ่าย + ของใกล้หมด (ดึงจาก catalog ผ่าน REST) |

## 3. Data Model (ER)

### auth_db
```
users
 ├─ id                   serial (PK)
 ├─ ssoId                uuid (unique) — JWT sub + cross-service reference
 ├─ email                varchar (unique)
 ├─ passwordHash         text (bcrypt)
 ├─ emailVerified        boolean
 ├─ verifyToken          text (nullable)
 ├─ resetToken           text (nullable)
 ├─ resetTokenExpiresAt  timestamptz (nullable)
 └─ createdAt            timestamptz

pending_registrations    (ก่อนบัญชีถูกสร้างจริง — ลบทิ้งเมื่อ set-password สำเร็จ)
 ├─ id                   serial (PK)
 ├─ email                varchar (unique)
 ├─ title                varchar  (mr|mrs|ms|unspecified)
 ├─ username             varchar
 ├─ firstName/lastName   varchar
 ├─ otpHash              text (bcrypt ของ OTP)
 ├─ otpExpiresAt         timestamptz
 ├─ attempts             int   (กันเดา OTP)
 ├─ emailVerified        boolean
 ├─ setupTicket          text (nullable) — ตั๋วชั่วคราวหลังยืนยัน OTP
 ├─ setupTicketExpiresAt timestamptz (nullable)
 └─ createdAt            timestamptz
```

### customer_db
```
customer_profiles
 ├─ id            serial (PK)
 ├─ ssoId         uuid (unique) — อ้างอิงถึง users.ssoId
 ├─ title         varchar  (mr|mrs|ms|unspecified)
 ├─ username      varchar (unique) — เป็น login identifier ด้วย
 ├─ firstName/lastName  varchar
 ├─ avatarBase64  text (nullable, data URL)
 ├─ status        varchar(280) (nullable)
 ├─ birthDate     date (nullable)
 ├─ createdAt     timestamptz
 └─ updatedAt     timestamptz
```

### catalog_db
```
items  (ShoppingItem)
 ├─ id            serial (PK)
 ├─ itemId        uuid (public id)
 ├─ ssoId         uuid — เจ้าของสินค้า (จาก JWT ผ่าน gateway)
 ├─ name          varchar
 ├─ category      enum (laundry|kitchen|bathroom|food|personal|other)
 ├─ size/unit     varchar (nullable)
 ├─ quantity      int
 ├─ unitLabel     varchar (nullable)
 ├─ price         numeric(12,2)
 ├─ store/buyer   varchar (nullable)
 ├─ purchaseDate  date (nullable)
 ├─ expiryDate    date (nullable)
 ├─ imageBase64   text (nullable, data URL)
 ├─ notifyRecurring boolean
 └─ createdAt     timestamptz
```

> analytics_db: เฟสนี้คำนวณสรุปแบบ on-demand (ดึงจาก catalog ผ่าน REST) จึงยังไม่มีตารางถาวร
> โครงสร้างเผื่ออนาคต: `MonthlySummarySnapshot` สำหรับ cache ผลลัพธ์

## 4. API Contract (ผ่าน Gateway, base `http://localhost:3000`)

### Auth — `/api/auth`
| Method | Path | คำอธิบาย |
|--------|------|----------|
| POST | `/register` | `{ email, title, username, firstName, lastName }` → ส่ง OTP → `{ email, otpExpiresInSec }` |
| POST | `/verify-otp` | `{ email, otp }` → `{ email, setupTicket }` |
| POST | `/resend-otp` | `{ email }` → `{ email, otpExpiresInSec }` |
| POST | `/set-password` | `{ email, setupTicket, password }` → `{ accessToken, refreshToken, user }` |
| POST | `/login` | `{ identifier, password }` |
| POST | `/refresh` | `{ refreshToken }` |
| GET | `/me` | โปรไฟล์ฝั่ง auth (ต้องมี token) |
| POST | `/change-password` | เปลี่ยนรหัสผ่าน (ต้องมี token) |
| POST | `/forgot-password` / `/reset-password` | ขอรีเซ็ต / รีเซ็ตด้วย token |

### Customer — `/api/customer`
| Method | Path | คำอธิบาย |
|--------|------|----------|
| GET | `/me` | โปรไฟล์ปัจจุบัน |
| PATCH | `/me` | แก้ไข `{ title?, username?, firstName?, lastName?, avatarBase64?, status?, birthDate? }` |

### Catalog — `/api/catalog`
| Method | Path | คำอธิบาย |
|--------|------|----------|
| POST | `/items` | เพิ่มสินค้า |
| GET | `/items` | รายการสินค้าทั้งหมด |
| GET | `/items/:itemId` | สินค้าเดียว |
| PATCH | `/items/:itemId` | แก้ไขสินค้า |
| DELETE | `/items/:itemId` | ลบสินค้า |

### Analytics — `/api/analytics`
| Method | Path | คำอธิบาย |
|--------|------|----------|
| GET | `/summary` | สรุปค่าใช้จ่ายรวม + แยกตามเดือน/หมวด |
| GET | `/expiring-soon?days=7` | รายการใกล้หมดภายใน N วัน |

## 5. OOP Design — Clean Architecture + Hexagonal (Ports & Adapters) (NFR-04)

แต่ละ service ที่มี business logic จัดโครงเป็น 4 ชั้น โดยให้ domain เป็นแกนกลางที่ไม่ผูกกับ framework

### 5.1 Dependency Rule
```
   interface (HTTP)  ─┐
                      ├─►  application (use cases)  ─►  domain (core)
   infrastructure ───┘                                      ▲
   (DB adapter / REST client / mailer) ── implements ports ─┘
```
- **domain** ไม่ import อะไรจาก NestJS / TypeORM (pure TypeScript)
- layer นอกพึ่งพา layer ในผ่าน **interface (port)** ไม่ใช่ concrete class

### 5.2 โครงสร้างโฟลเดอร์ (ต่อ service)
```
src/
├─ domain/
│  ├─ model/            # pure domain class + behavior
│  └─ port/             # interface (outbound port)
├─ application/
│  ├─ dto/              # command/result shapes
│  └─ use-case/         # use cases
├─ infrastructure/
│  ├─ persistence/      # ORM entity + mapper + repository adapter
│  ├─ customer|catalog/ # REST client adapter (service-to-service)
│  └─ mail/             # mailer adapter (dev: Ethereal + log)
└─ interface/
   └─ http/             # controller + request DTO (class-validator) + guard
```

### 5.3 Ports & Adapters ต่อ service
| Service | Inbound adapter | Outbound port(s) | Outbound adapter |
|---------|-----------------|------------------|------------------|
| auth | HTTP controller | `UserRepositoryPort`, `PendingRegistrationRepositoryPort`, `MailerPort`, `CustomerClientPort` | TypeORM repos, DevMailer, `CustomerHttpClient` |
| customer | HTTP controller | `CustomerRepositoryPort` | TypeORM repo (→ customer_db) |
| catalog | HTTP controller | `ItemRepositoryPort` | TypeORM repo (→ catalog_db) |
| analytics | HTTP controller | `CatalogPort` | `HttpCatalogClient` (→ REST ไป catalog) |
| api-gateway | HTTP controller | - | proxy adapter ไป service ปลายทาง (ชั้นบาง) |

### 5.4 OOP เน้นอะไร
- **Encapsulation**: domain model ถือ state + behavior (เช่น `PendingRegistration.isOtpExpired()`, `isTicketValid()`; item `subtotal()`, `daysUntilExpiry()`)
- **Dependency Inversion**: use case ขึ้นกับ port; NestJS DI inject adapter จริงผ่าน token
- **Separation of concerns**: ORM entity แยกจาก domain model ด้วย mapper
- **Testability**: use case เทสได้โดย mock port โดยไม่ต้องมี DB จริง

## 6. Security Design
- รหัสผ่าน: bcrypt hash (ไม่เก็บ plaintext)
- JWT: access token (สั้น) + refresh token (ยาว, secret แยก) — `sub = ssoId`
- OTP: hash ด้วย bcrypt, มี `otpExpiresAt` + `attempts` จำกัดจำนวนครั้งเดา
- setup ticket: random token อายุสั้น ใช้ครั้งเดียวตอน set-password
- PIN/ไบโอเมตริก: **local-only** ฝั่ง client (PIN เก็บ SHA-256 + salt ใน secure storage ไม่ส่งขึ้น server)
- Gateway ตรวจ JWT แล้วส่ง identity ต่อเป็น header `x-sso-id` ให้ service ปลายทาง

## 7. Deployment
- ทุก service + DB เป็น container แยกผ่าน `docker-compose.yml` (4 DB + 5 services)
- Flutter เรียก `http://localhost:3000` (gateway); Android emulator ใช้ `10.0.2.2`

## 8. การ map ความต้องการ → การออกแบบ
| Requirement | รองรับด้วย |
|-------------|-----------|
| FR-01, FR-02 | auth-service (pending+OTP+set-password, login/refresh/reset) |
| FR-03 | customer-service (profile + title) |
| FR-04, FR-05 | catalog-service CRUD + ฝั่ง client สแกนบาร์โค้ด (OpenFoodFacts) |
| FR-06, FR-07 | analytics-service `/summary`, `/expiring-soon` + budget ฝั่ง client |
| FR-08 | PIN/biometric ฝั่ง client (local-only) |
| NFR-01, NFR-02 | 5 services + 4 DB แยก |
| NFR-03 | api-gateway + REST |
| NFR-04 | Clean Architecture + Hexagonal |
| NFR-07 | bcrypt, JWT, OTP hash+expiry+attempts, PIN hash local |
| NFR-05 | docker-compose |
