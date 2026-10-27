# Scalability Roadmap — Homeful

เอกสารนี้ตอบคำถาม "ถ้าในอนาคตระบบซับซ้อนขึ้น จะ scale ยังไง"
โดยแยกเป็น (ก) สิ่งที่ออกแบบไว้แล้วให้พร้อมโต และ (ข) แนวทางปรับเมื่อถึงจุดที่ต้องการ

> สถานะปัจจุบัน: 5 services (api-gateway, auth, customer, catalog, analytics) + 4 DB แยก,
> มีระบบ auth (JWT + OTP) ที่ gateway แล้ว

## ส่วนที่ 1 — รากฐานที่ "พร้อมโต" อยู่แล้ว (ทำไว้แล้ว)

| รากฐาน | ช่วยเรื่อง scale อย่างไร |
|--------|--------------------------|
| **Microservice แยก service** | แต่ละ service deploy/scale แยกกันได้ ตาม load ที่ต่างกัน |
| **Database-per-service** | ไม่มี DB กลางเป็นคอขวด; แต่ละ service เลือก DB/ปรับ schema ได้อิสระ |
| **Clean Architecture + Hexagonal (ports & adapters)** | เปลี่ยน infra (DB, transport) ได้โดยไม่แตะ domain → ลดต้นทุนการเปลี่ยนแปลง |
| **API Gateway เป็นประตูเดียว** | เพิ่ม cross-cutting concern (auth, rate-limit, cache) ที่จุดเดียว; client ไม่ต้องรู้ว่ามีกี่ service |
| **สื่อสารผ่าน REST interface** | สลับ service เป็น instance หลายตัวหลัง load balancer ได้ |
| **Stateless services** | ทุก service ไม่เก็บ state ใน memory → scale horizontally (เพิ่ม replica) ได้ทันที |

เพราะ `analytics` คุยกับ `catalog` ผ่าน **port (interface)** + adapter การเปลี่ยน transport
ภายหลัง (เช่น REST → gRPC → message queue) ทำที่ adapter layer อย่างเดียว domain ไม่กระทบ

## ส่วนที่ 2 — เมื่อซับซ้อนขึ้น ปรับอะไร (roadmap ตามระดับการโต)

### ระดับ 1: traffic เริ่มเยอะ (scale แนวนอน)
- รัน service หลาย replica หลัง load balancer (เช่น `docker compose up --scale catalog-service=3` หรือ Kubernetes Deployment + HPA)
- เพิ่ม **connection pooling** / read-replica ให้ PostgreSQL ของ catalog
- ใส่ **cache** (Redis) ที่ gateway หรือ analytics สำหรับ summary ที่อ่านบ่อย

### ระดับ 2: การคำนวณ/รายงานหนักขึ้น
- analytics เปลี่ยนจาก "คำนวณสด" → เก็บ **MonthlySummarySnapshot** ใน analytics_db (มี schema เผื่อไว้แล้วใน design doc)
- อัปเดต snapshot แบบ **event-driven**: catalog ยิง event เมื่อข้อมูลเปลี่ยน แทนที่ analytics จะ poll

### ระดับ 3: ต้องการ decoupling จริง (async)
- ใส่ **message broker** (RabbitMQ / Kafka / NATS)
- catalog publish event (`ItemAdded`, `ItemUpdated`); analytics subscribe
- ได้ eventual consistency, ทนทานต่อ service ล่มชั่วคราว, ลด coupling แบบ synchronous
- NestJS รองรับผ่าน `@nestjs/microservices` — adapter ใหม่เสียบที่ port เดิม (domain ไม่เปลี่ยน)

### ระดับ 4: มี client/ทีมหลายแบบ
- พิจารณา **GraphQL / BFF** ที่ gateway (เคยคุยกันไว้ — ยังไม่จำเป็นตอนนี้)
- แยก service เพิ่มตาม bounded context (เช่น แยก `notification-service` เมื่อมี push จริง — ปัจจุบันมี `auth-service`/`customer-service` แล้ว)

### ระดับ 5: operational maturity
- **Observability**: centralized logging, tracing (OpenTelemetry), metrics (Prometheus/Grafana)
- **CI/CD**: build/test/deploy แยกต่อ service
- **Resilience**: retry, circuit breaker ที่ gateway/adapter, health check (มี healthcheck ใน docker-compose แล้ว)
- **Schema migration**: เปลี่ยนจาก `synchronize: true` (dev) → migration จริง (TypeORM migrations) ก่อนขึ้น production

## ส่วนที่ 3 — หนี้ทางเทคนิคที่ต้องเคลียร์ก่อน production
| ปัจจุบัน (dev) | ต้องเปลี่ยนก่อน production |
|----------------|---------------------------|
| `synchronize: true` | ใช้ migration แทน (กัน data loss) |
| OTP/อีเมลผ่าน Ethereal + log console | ต่อ SMTP/SES/SendGrid จริง |
| ไม่มี cache | เพิ่ม cache layer ตาม hotspot |
| synchronous REST ระหว่าง service | พิจารณา async event เมื่อ coupling เป็นปัญหา |
| คำนวณ analytics สด | snapshot + event-driven update |
| JWT secret เป็น dev default ใน env | ใช้ secret manager + rotate keys |

## สรุป
สถาปัตยกรรมปัจจุบันถูกออกแบบให้ **โตได้โดยไม่ต้องรื้อ**: domain ถูกกันออกจาก infra ด้วย ports & adapters,
service เป็น stateless + DB แยก, และ gateway เป็นจุดรวม cross-cutting concern
การ scale ส่วนใหญ่จึงเป็นการ "เพิ่ม adapter / เพิ่ม replica / เพิ่ม layer" มากกว่าการเขียนใหม่
