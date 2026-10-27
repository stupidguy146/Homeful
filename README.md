<<<<<<< HEAD
# Room Shopping List — จดลิสต์ซื้อของเข้าห้องรายเดือน

ระบบจดบันทึกรายการซื้อของเข้าห้องในแต่ละเดือน: ชื่อของ จำนวน ราคา วันหมด
พร้อมสรุปยอดเงินรายเดือนและรายการที่ใกล้หมด

สถาปัตยกรรม: **Microservice** (NestJS) + **PostgreSQL** (database-per-service) + **Flutter** client
ออกแบบด้วย **Clean Architecture + Hexagonal (Ports & Adapters)** และทำตามกระบวนการ **SDLC**

## สถาปัตยกรรม

```
Flutter ──REST──► api-gateway (3000)
                     ├──REST──► catalog-service (3001) ──► catalog_db  (5433)
                     └──REST──► analytics-service (3002) ──► analytics_db (5434)
                                       │
                                       └──REST──► catalog-service (ดึงข้อมูลมาคำนวณ)
```

- **api-gateway** (port 3000): ประตูเดียวสำหรับ client, proxy ไป service ปลายทาง
- **catalog-service** (port 3001): CRUD เดือน + รายการของ (เจ้าของ `catalog_db`)
- **analytics-service** (port 3002): ยอดรวมรายเดือน + ของใกล้หมด (ดึงข้อมูลจาก catalog ผ่าน REST, ไม่อ่าน DB ข้าม service)

## โครงสร้างโปรเจกต์

```
room-shopping-list/
├─ docker-compose.yml          # 2 DB + 3 services
├─ docs/
│  ├─ 01-requirements.md        # SDLC: requirements
│  ├─ 02-design.md              # SDLC: architecture, ER, API contract, Clean Arch
│  └─ 03-scalability.md         # แนวทาง scale เมื่อระบบโต
├─ backend/
│  ├─ catalog-service/          # domain / application / infrastructure / interface
│  ├─ analytics-service/        # domain / application / infrastructure / interface
│  └─ api-gateway/              # thin REST proxy
└─ frontend/                    # Flutter app (lib: config, models, services, screens)
```

แต่ละ backend service จัดชั้นตาม Clean Architecture:
- `domain/` — model (pure TS) + port (interface) — ไม่ผูก framework/DB
- `application/` — use cases
- `infrastructure/` — adapter จริง (persistence / REST client)
- `interface/` — HTTP controller

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
- catalog-service: http://localhost:3001/catalog
- analytics-service: http://localhost:3002/analytics
- PostgreSQL: catalog_db @ 5433, analytics_db @ 5434

หยุด: `docker compose down` (ลบข้อมูลด้วย: `docker compose down -v`)

### ตัวเลือก B — รัน backend แบบ local (ไม่ผ่าน Docker)
ต้องมี PostgreSQL 2 ฐานข้อมูลก่อน (หรือรันเฉพาะ DB ผ่าน Docker):
```bash
docker compose up catalog-db analytics-db
```
จากนั้นแต่ละ service:
```bash
# catalog-service
cd backend/catalog-service
npm install
DB_HOST=localhost DB_PORT=5433 DB_USER=catalog DB_PASSWORD=catalog_pass DB_NAME=catalog_db PORT=3001 npm run start

# analytics-service (อีก terminal)
cd backend/analytics-service
npm install
PORT=3002 CATALOG_SERVICE_URL=http://localhost:3001 npm run start

# api-gateway (อีก terminal)
cd backend/api-gateway
npm install
PORT=3000 CATALOG_SERVICE_URL=http://localhost:3001 ANALYTICS_SERVICE_URL=http://localhost:3002 npm run start
```

### รัน Flutter frontend
> ต้องติดตั้ง Flutter SDK ก่อน: https://docs.flutter.dev/get-started/install
```bash
cd frontend
flutter pub get
flutter run            # เลือก device/emulator
# หรือรันบนเว็บ:
flutter run -d chrome
```

**หมายเหตุ base URL:**
- Web / iOS simulator / desktop: ใช้ค่า default `http://localhost:3000`
- Android emulator: ต้องชี้ `10.0.2.2` แทน localhost:
  ```bash
  flutter run --dart-define=GATEWAY_URL=http://10.0.2.2:3000
  ```

---

## API (ผ่าน Gateway, base http://localhost:3000)

### Catalog — `/api/catalog`
| Method | Path | คำอธิบาย |
|--------|------|----------|
| POST | `/months` | สร้างเดือน `{ year, month, note? }` |
| GET | `/months` | รายการเดือนทั้งหมด |
| GET | `/months/:id` | เดือนเดียว (รวม items + ยอดรวม) |
| PATCH | `/months/:id` | แก้ไขเดือน |
| DELETE | `/months/:id` | ลบเดือน (ลบ items ตาม) |
| POST | `/months/:id/items` | เพิ่มรายการ `{ name, quantity, unitPrice, expiryDate? }` |
| GET | `/months/:id/items` | รายการของในเดือน |
| PATCH | `/items/:itemId` | แก้ไขรายการ |
| DELETE | `/items/:itemId` | ลบรายการ |

### Analytics — `/api/analytics`
| Method | Path | คำอธิบาย |
|--------|------|----------|
| GET | `/months/:id/summary` | ยอดรวมของเดือน |
| GET | `/summary` | สรุปยอดรวมทุกเดือน |
| GET | `/expiring-soon?days=7` | รายการใกล้หมดภายใน N วัน |

### ตัวอย่าง
```bash
# สร้างเดือน
curl -X POST http://localhost:3000/api/catalog/months \
  -H 'Content-Type: application/json' \
  -d '{"year":2026,"month":10,"note":"ตุลาคม"}'

# เพิ่มรายการ (แทน <id> ด้วย month id ที่ได้)
curl -X POST http://localhost:3000/api/catalog/months/<id>/items \
  -H 'Content-Type: application/json' \
  -d '{"name":"ยาสีฟัน","quantity":2,"unitPrice":55.00,"expiryDate":"2026-11-30"}'

# ของใกล้หมดใน 14 วัน
curl "http://localhost:3000/api/analytics/expiring-soon?days=14"
```

---

## สถานะการ verify
- ✅ catalog-service: `npm run build` ผ่าน (exit 0)
- ✅ analytics-service: `npm run build` ผ่าน (exit 0)
- ✅ api-gateway: `npm run build` ผ่าน (exit 0)
- ⚠️ Flutter: ยังไม่ได้ verify ด้วย `flutter analyze` เพราะเครื่องที่สร้างยังไม่ได้ติดตั้ง Flutter SDK — โปรดรัน `flutter pub get && flutter analyze` หลังติดตั้ง

## หมายเหตุสำหรับ dev/production
- `synchronize: true` ใช้เฉพาะ dev (สร้างตารางอัตโนมัติ) — ก่อนขึ้น production ให้เปลี่ยนเป็น TypeORM migrations
- ยังไม่มีระบบ auth (single-user) — ดู `docs/03-scalability.md` สำหรับแนวทางเพิ่มเมื่อระบบโต
=======
# Homeful
>>>>>>> 71bab3f105c2e6940db09b46423954f2849732f5
