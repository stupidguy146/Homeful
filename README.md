# Homeful — ตัวช่วยจัดการของใช้ในบ้าน

ระบบติดตามของใช้ในบ้าน: บันทึกสินค้า (ชื่อ จำนวน ราคา ขนาด หมวดหมู่ วันหมดอายุ ร้านค้า ผู้ซื้อ รูปภาพ),
สรุปค่าใช้จ่าย/งบประมาณ, แจ้งเตือนของใกล้หมด, สแกนบาร์โค้ดเติมข้อมูลอัตโนมัติ
พร้อมระบบสมาชิก (สมัคร + ยืนยัน OTP ทางอีเมล + ตั้งรหัสผ่าน), โปรไฟล์ลูกค้า, และล็อกแอปด้วย PIN/ไบโอเมตริก

สถาปัตยกรรม: **Microservice** (NestJS) + **PostgreSQL** (database-per-service) + **Flutter** client (รองรับ TH/EN)
ออกแบบด้วย **Clean Architecture + Hexagonal (Ports & Adapters)** ตามกระบวนการ **SDLC**

## สถาปัตยกรรม

```
Flutter (homeful) ──REST──► api-gateway (3000)
                               ├──► auth-service      (3003) ──► auth_db      (5435)
                               │        └──REST──► customer-service (provision profile)
                               ├──► customer-service  (3004) ──► customer_db  (5436)
                               ├──► catalog-service   (3001) ──► catalog_db   (5433)
                               └──► analytics-service (3002) ──► analytics_db (5434)
                                          └──REST──► catalog-service (ดึงข้อมูลมาคำนวณ)
```

- **api-gateway** (3000): ประตูเดียวสำหรับ client, proxy ไป service ปลายทาง, ตรวจ JWT สำหรับ route ที่ต้องล็อกอิน
- **auth-service** (3003): สมัคร/ยืนยัน OTP/ตั้งรหัสผ่าน/ล็อกอิน/รีเฟรช/เปลี่ยน-รีเซ็ตรหัสผ่าน (เจ้าของ `auth_db`)
- **customer-service** (3004): โปรไฟล์ลูกค้า (คำนำหน้า/ชื่อ/username/รูป/สถานะ/วันเกิด) (เจ้าของ `customer_db`)
- **catalog-service** (3001): CRUD รายการสินค้า (เจ้าของ `catalog_db`)
- **analytics-service** (3002): สรุปค่าใช้จ่าย + ของใกล้หมด (ดึงข้อมูลจาก catalog ผ่าน REST ไม่อ่าน DB ข้าม service)

## โครงสร้างโปรเจกต์

```
room-shopping-list/
├─ docker-compose.yml           # 4 DB + 5 services
├─ docs/
│  ├─ 01-requirements.md         # SDLC: requirements
│  ├─ 02-design.md               # SDLC: architecture, ER, API contract, Clean Arch
│  └─ 03-scalability.md          # แนวทาง scale เมื่อระบบโต
├─ backend/
│  ├─ api-gateway/               # thin REST proxy + JWT verify
│  ├─ auth-service/              # สมัคร/OTP/ตั้งรหัสผ่าน/ล็อกอิน
│  ├─ customer-service/          # โปรไฟล์ลูกค้า
│  ├─ catalog-service/           # CRUD สินค้า
│  └─ analytics-service/         # สรุป/ของใกล้หมด
├─ design/                       # design tokens (Figma) + guideline
└─ frontend/                     # Flutter app (config, models, services, screens, widgets, i18n)
```

แต่ละ backend service จัดชั้นตาม Clean Architecture:
- `domain/` — model (pure TS) + port (interface) — ไม่ผูก framework/DB
- `application/` — use cases + DTO
- `infrastructure/` — adapter จริง (persistence / REST client / mailer)
- `interface/` — HTTP controller + request DTO (class-validator)

## ความต้องการของเครื่อง (Prerequisites)
- Docker + Docker Compose (รันทั้งระบบง่ายสุด)
- หรือ Node.js 20+ (รัน backend แบบ local ไม่ผ่าน Docker)
- Flutter SDK 3.3+ (สำหรับรัน frontend)

---

## วิธีรัน

### ตัวเลือก A — รันทั้งหมดด้วย Docker Compose (แนะนำ)
```bash
cd room-shopping-list
docker compose up --build
```
จะได้:
- API Gateway: http://localhost:3000
- auth-service: http://localhost:3003/auth
- customer-service: http://localhost:3004/customer
- catalog-service: http://localhost:3001/catalog
- analytics-service: http://localhost:3002/analytics
- PostgreSQL: catalog_db @ 5433, analytics_db @ 5434, auth_db @ 5435, customer_db @ 5436

หยุด: `docker compose down` (ลบข้อมูลด้วย: `docker compose down -v`)

### ตัวเลือก B — รัน backend แบบ local (ไม่ผ่าน Docker)
รันเฉพาะ DB ผ่าน Docker ก่อน แล้วรันแต่ละ service ด้วย `npm install && npm run start`
(ค่า env อยู่ในไฟล์ `.env.example` ของแต่ละ service) ลำดับที่แนะนำ: customer → auth → catalog → analytics → gateway

### รัน Flutter frontend
> ต้องติดตั้ง Flutter SDK ก่อน: https://docs.flutter.dev/get-started/install
```bash
cd frontend
flutter pub get
flutter run              # เลือก device/emulator
# หรือรันบนเว็บ:
flutter run -d chrome
```

**หมายเหตุ base URL** (ค่า `GATEWAY_URL`, default `http://localhost:3000`):
- Web / iOS simulator / desktop: ใช้ค่า default ได้เลย
- Android emulator: ต้องชี้ `10.0.2.2`:
  ```bash
  flutter run --dart-define=GATEWAY_URL=http://10.0.2.2:3000
  ```

---

## ฟีเจอร์ฝั่ง Frontend (Flutter "homeful")
- **สมัครสมาชิก**: เลือกคำนำหน้า (นาย/นาง/นางสาว/ไม่ระบุ) → กรอกข้อมูล → ยืนยัน **OTP 6 หลักทางอีเมล** → ตั้งรหัสผ่าน (มี checklist เงื่อนไข + แถบวัดความแข็งแรง)
- **ล็อกแอป**: ตั้ง **PIN 6 หลัก** + ปลดล็อกด้วย **ลายนิ้วมือ/สแกนหน้า** (บนมือถือ; เว็บใช้ PIN) และเปลี่ยน PIN ได้จากเมนู
- **สินค้า**: เพิ่มได้ 2 แบบ — **สแกนบาร์โค้ด** (เติมชื่อ/ยี่ห้อ/ขนาด/หมวด/ร้าน/รูปอัตโนมัติ) หรือ **กรอกเอง**; วันที่ซื้อ prefill เป็นวันนี้, ผู้ซื้อ prefill เป็นชื่อผู้ใช้
- **รายการสินค้า**: ค้นหา + กรองหมวด, **ปัดซ้ายเพื่อลบ** (มี modal ยืนยัน), ไอคอนประจำหมวด
- **งบประมาณ**: ตั้งงบ + แถบความคืบหน้าเทียบยอดใช้จริง (แดงเมื่อเกินงบ) ทั้งในหน้า Home และหน้างบประมาณ
- **โปรไฟล์**: แก้คำนำหน้า/ชื่อ/username/รูป/วันเกิด, แจ้งเตือนอีเมลยังไม่ยืนยัน
- **UX กลาง**: snackbar แบ่งสีตามผล (เขียว=สำเร็จ / แดง=ล้มเหลว / น้ำเงิน=ข้อมูล), modal ยืนยันสำหรับ action ที่ลบข้อมูล, รองรับ TH/EN + ธีมสว่าง/มืด, ธงภาษาในหน้าตั้งค่า

---

## API (ผ่าน Gateway, base http://localhost:3000)

### Auth — `/api/auth`
| Method | Path | คำอธิบาย |
|--------|------|----------|
| POST | `/register` | เริ่มสมัคร `{ email, title, username, firstName, lastName }` → ส่ง OTP → `{ email, otpExpiresInSec }` |
| POST | `/verify-otp` | ยืนยัน OTP `{ email, otp }` → `{ email, setupTicket }` |
| POST | `/resend-otp` | ขอ OTP ใหม่ `{ email }` |
| POST | `/set-password` | ตั้งรหัสผ่าน+สร้างบัญชี `{ email, setupTicket, password }` → `{ accessToken, refreshToken, user }` |
| POST | `/login` | ล็อกอิน `{ identifier (email/username), password }` |
| POST | `/refresh` | ต่ออายุ token `{ refreshToken }` |
| GET | `/me` | โปรไฟล์ฝั่ง auth (ต้องมี token) |
| POST | `/change-password` | เปลี่ยนรหัสผ่าน (ต้องมี token) |
| POST | `/forgot-password` | ขอรีเซ็ตรหัสผ่าน `{ email }` |
| POST | `/reset-password` | รีเซ็ตด้วย token `{ token, newPassword }` |

### Customer — `/api/customer`
| Method | Path | คำอธิบาย |
|--------|------|----------|
| GET | `/me` | โปรไฟล์ผู้ใช้ปัจจุบัน (ต้องมี token) |
| PATCH | `/me` | แก้ไขโปรไฟล์ `{ title?, username?, firstName?, lastName?, avatarBase64?, status?, birthDate? }` |

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

### ตัวอย่าง flow สมัครสมาชิก
```bash
# 1) เริ่มสมัคร (ได้ OTP ส่งเข้าอีเมล; dev จะ log [DEV OTP] ที่ console ของ auth-service)
curl -X POST http://localhost:3000/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"user@example.com","title":"mr","username":"user1","firstName":"User","lastName":"Example"}'

# 2) ยืนยัน OTP → ได้ setupTicket
curl -X POST http://localhost:3000/api/auth/verify-otp \
  -H 'Content-Type: application/json' \
  -d '{"email":"user@example.com","otp":"123456"}'

# 3) ตั้งรหัสผ่าน → ได้ accessToken (ล็อกอินอัตโนมัติ)
curl -X POST http://localhost:3000/api/auth/set-password \
  -H 'Content-Type: application/json' \
  -d '{"email":"user@example.com","setupTicket":"<ticket>","password":"Passw0rd!x"}'
```

---

## สถานะการ verify (เซสชันล่าสุด)
- ✅ backend 5 services: `npm run build` ผ่านทั้งหมด (exit 0)
- ✅ auth OTP flow ทดสอบ end-to-end ผ่าน gateway: register → OTP → verify → set-password → login + โปรไฟล์มีคำนำหน้าถูกต้อง
- ✅ frontend: `flutter analyze` ไม่มี issue, `flutter test` ผ่าน, `flutter build web` สำเร็จ

## หมายเหตุสำหรับ dev/production
- OTP ในโหมด dev ถูก log ที่ console ของ auth-service (`[DEV OTP] to=... code=...`) และส่งผ่าน Ethereal (preview URL) — เปลี่ยนเป็น SMTP/SES/SendGrid จริงก่อน production
- PIN/ไบโอเมตริกเป็น **local-only** (เก็บ PIN แบบ hash ในเครื่อง ไม่ส่งขึ้น server)
- `synchronize: true` ใช้เฉพาะ dev (สร้างตารางอัตโนมัติ) — ก่อน production เปลี่ยนเป็น TypeORM migrations
- ดู `docs/03-scalability.md` สำหรับแนวทาง scale และหนี้ทางเทคนิคที่ต้องเคลียร์
