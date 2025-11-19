# Backend - Local Service Platform

API Backend cho hệ thống đặt lịch dịch vụ tại nhà, xây dựng bằng **NestJS** + **Prisma** + **PostgreSQL (PostGIS)**.

## 📋 Yêu cầu

- **Node.js** >= 18.x
- **PostgreSQL** >= 13 (với extension PostGIS)
- **Docker** (tùy chọn, để chạy PostgreSQL)

---

## 🚀 Quick Start

### **Option 1: Sử dụng Docker (Khuyến nghị)**

```bash
# 1. Khởi động PostgreSQL container
docker run -d \
  --name local-service-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=local_service_platform \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  postgis/postgis:15-3.3

# 2. Chờ 5 giây để database khởi động
# Sau đó enable PostGIS extensions
docker exec -it local-service-postgres psql -U postgres -d local_service_platform \
  -c "CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS pgcrypto;"

# 3. Setup backend
cd apps/backend
cp .env.example .env  # (nếu chưa có .env)
npm install
npx prisma migrate dev --name init
npx prisma generate
npm run prisma:seed

# 4. Chạy development server
npm run dev
```

**Windows PowerShell:**
```powershell
# 1. Khởi động PostgreSQL
docker run -d `
  --name local-service-postgres `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=local_service_platform `
  -p 5432:5432 `
  -v postgres_data:/var/lib/postgresql/data `
  postgis/postgis:15-3.3

# 2. Enable extensions
Start-Sleep -Seconds 5
docker exec -it local-service-postgres psql -U postgres -d local_service_platform `
  -c "CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS pgcrypto;"

# 3. Setup backend (tương tự như trên)
```

### **Option 2: PostgreSQL đã cài sẵn**

```bash
# 1. Tạo database và enable extensions
psql -U postgres
CREATE DATABASE local_service_platform;
\c local_service_platform
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
\q

# 2. Tạo .env file
cp .env.example .env
# Edit .env với credentials của bạn

# 3. Setup backend
npm install
npx prisma migrate dev --name init
npx prisma generate
npm run prisma:seed

# 4. Chạy server
npm run dev
```

---

## 📂 Cấu trúc thư mục

```
apps/backend/
├── prisma/                    # Prisma configuration
│   ├── schema.prisma         # Database schema (28 bảng)
│   ├── seed.ts               # Seed data (roles, permissions, services)
│   └── migrations/           # Migration files
│
├── src/                       # NestJS source code
│   ├── prisma/               # Prisma module
│   │   ├── prisma.service.ts # PrismaClient service
│   │   └── prisma.module.ts  # Global Prisma module
│   ├── app.module.ts         # Root module
│   ├── app.controller.ts
│   ├── app.service.ts
│   └── main.ts               # Entry point
│
├── .env                       # Environment variables (không commit)
├── .env.example              # Template cho .env
└── package.json
```

---

## ⚙️ Environment Variables

Tạo file `.env` (copy từ `.env.example`):

```env
# Database
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/local_service_platform?schema=public"

# Application
NODE_ENV=development
PORT=3000

# JWT (sẽ dùng sau)
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-key
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
```

**Các DATABASE_URL khác:**

```env
# Docker (default)
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/local_service_platform?schema=public"

# Docker network (backend cũng chạy trong Docker)
DATABASE_URL="postgresql://postgres:postgres@postgres:5432/local_service_platform?schema=public"

# PostgreSQL local
DATABASE_URL="postgresql://username:password@localhost:5432/local_service_platform?schema=public"

# Production với SSL
DATABASE_URL="postgresql://user:pass@host:5432/dbname?schema=public&sslmode=require"
```

---

## 🗄️ Database Schema

Hệ thống gồm **28 bảng** chia thành **7 modules**:

| Module | Bảng | Mô tả |
|--------|------|-------|
| **User & Auth** | 4 | users, user_profiles, otp_codes, sessions |
| **RBAC** | 4 | roles, permissions, user_roles, role_permissions |
| **Service & Provider** | 5 | provider_profiles, service_categories, services, provider_services, favorites |
| **Booking & Location** | 3 | addresses, bookings, booking_events |
| **Payment & Wallet** | 3 | payments, wallets, wallet_transactions |
| **Interaction** | 4 | reviews, disputes, conversations, messages |
| **System & Utilities** | 5 | media, notifications, audit_logs, blockchain_transactions, settings |

Chi tiết đầy đủ xem tại [DATABASE.md](../../DATABASE.md)

---

## 🔧 Prisma Commands

```bash
# Generate Prisma Client (sau khi thay đổi schema)
npm run prisma:generate
# hoặc: npx prisma generate

# Tạo migration mới
npm run prisma:migrate
# hoặc: npx prisma migrate dev --name migration_name

# Apply migrations (production)
npm run prisma:migrate:deploy

# Seed database
npm run prisma:seed

# Mở Prisma Studio (Database GUI)
npm run prisma:studio
# Truy cập: http://localhost:5555

# Reset database (xóa tất cả data)
npm run prisma:reset
```

---

## 🎯 Development Scripts

```bash
# Development mode (với hot reload)
npm run dev
# hoặc: npm run start:dev

# Build production
npm run build

# Start production
npm run start:prod

# Linting
npm run lint

# Testing
npm run test
npm run test:watch
npm run test:e2e
npm run test:cov
```

---

## 🐳 Docker Commands (nếu dùng Docker)

```bash
# Khởi động container
docker start local-service-postgres

# Dừng container
docker stop local-service-postgres

# Xem logs
docker logs -f local-service-postgres

# Kết nối vào database
docker exec -it local-service-postgres psql -U postgres -d local_service_platform

# Xóa container + data
docker rm -f local-service-postgres
docker volume rm postgres_data

# Backup database
docker exec local-service-postgres pg_dump -U postgres local_service_platform > backup.sql

# Restore database
docker exec -i local-service-postgres psql -U postgres -d local_service_platform < backup.sql
```

---

## 📊 Seed Data

Sau khi chạy `npm run prisma:seed`, database sẽ có:

✅ **4 Roles:**
- `customer` - Khách hàng
- `provider` - Nhà cung cấp dịch vụ
- `moderator` - Quản trị viên cấp thấp
- `super_admin` - Quản trị viên hệ thống

✅ **13 Permissions:**
- `bookings.create`, `bookings.update`, `bookings.cancel`, `bookings.view`
- `providers.verify`, `providers.suspend`
- `disputes.manage`, `disputes.resolve`
- `users.ban`, `users.unban`
- `reports.view`, `reports.export`
- `settings.update`

✅ **5 Service Categories:**
- Điện lạnh
- Vệ sinh
- Sửa chữa điện
- Ống nước
- Nội thất

✅ **8 Services** (mẫu)

✅ **5 Settings** (cấu hình hệ thống)

---

## 🔒 Security Notes

- ❗ **Đừng commit file `.env`** vào Git
- ✅ Sử dụng `.env.example` làm template
- ✅ Thay đổi `JWT_SECRET` trong production
- ✅ Sử dụng SSL connection cho production database

---

## 🐛 Troubleshooting

### **Lỗi: `DATABASE_URL` not found**
```bash
# Đảm bảo file .env đã tồn tại
cp .env.example .env
```

### **Lỗi: Cannot connect to database**
```bash
# Kiểm tra PostgreSQL đang chạy
docker ps

# Hoặc nếu dùng local:
pg_isready -h localhost -p 5432
```

### **Lỗi: PostGIS extension not found**
```bash
# Enable PostGIS
docker exec -it local-service-postgres psql -U postgres -d local_service_platform \
  -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

### **Port 5432 đã bị chiếm**
```bash
# Đổi port trong docker:
docker run -p 5433:5432 ...

# Update .env:
DATABASE_URL="postgresql://postgres:postgres@localhost:5433/..."
```

---

## 📚 Tài liệu tham khảo

- [NestJS Documentation](https://docs.nestjs.com/)
- [Prisma Documentation](https://www.prisma.io/docs)
- [PostGIS Documentation](https://postgis.net/documentation/)
- [DATABASE.md](../../DATABASE.md) - Chi tiết thiết kế database

---

## 🤝 Team Guidelines

1. **Tạo migration mới:**
   ```bash
   npx prisma migrate dev --name descriptive_name
   ```

2. **Sau khi pull code:**
   ```bash
   npm install
   npx prisma generate
   npx prisma migrate dev
   ```

3. **Trước khi commit:**
   ```bash
   npm run lint
   npm run test
   ```

---

**Version:** 1.0.0  
**Last Updated:** 2025-01-16
