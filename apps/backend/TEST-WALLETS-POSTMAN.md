# 🧪 Hướng Dẫn Test Wallets API với Postman

## 📥 Bước 1: Import Collection vào Postman

1. Mở **Postman**
2. Click **Import** (góc trên bên trái)
3. Chọn file `Wallets-API.postman_collection.json`
4. Click **Import**

✅ Collection "Wallets API - Local Service Platform" sẽ xuất hiện trong sidebar

---

## 🚀 Bước 2: Kiểm tra Backend đang chạy

Đảm bảo backend đang chạy trên `http://localhost:3000`:

```powershell
# Trong terminal apps/backend
pnpm start:dev
```

Kiểm tra log thấy:
```
[Nest] LOG [RouterExplorer] Mapped {/wallets/balance, GET} route
[Nest] LOG [RouterExplorer] Mapped {/wallets/deposit, POST} route
[Nest] LOG [RouterExplorer] Mapped {/wallets/withdraw, POST} route
```

---

## 🔐 Bước 3: Authentication (Lấy Token)

### 3.1. Register User (lần đầu)

**Request:**
```
POST http://localhost:3000/auth/register
Content-Type: application/json

{
  "phone": "0987654321",
  "password": "Test@123",
  "fullName": "Test User"
}
```

**Expected Response (201 Created):**
```json
{
  "user": {
    "id": "1",
    "phone": "0987654321",
    "fullName": "Test User"
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 3.2. Login (lấy token mới)

**Request:**
```
POST http://localhost:3000/auth/login

{
  "phone": "0987654321",
  "password": "Test@123"
}
```

**Expected Response (200 OK):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

✅ **Token sẽ tự động lưu vào biến `{{accessToken}}`** (nhờ Test Script trong collection)

---

## 💰 Bước 4: Test Wallets Endpoints

### TEST 1: Get Wallet Balance

**Request:**
```
GET http://localhost:3000/wallets/balance
Authorization: Bearer {{accessToken}}
```

**Expected Response (200 OK):**
```json
{
  "balance": "0",
  "currency": "VND",
  "totalTransactions": 0,
  "createdAt": "2025-11-26T08:00:00.000Z"
}
```

✅ **Ý nghĩa:** Wallet tự động tạo khi user đăng ký, balance ban đầu = 0

---

### TEST 2: Get Transaction History

**Request:**
```
GET http://localhost:3000/wallets/transactions?page=1&limit=20
Authorization: Bearer {{accessToken}}
```

**Expected Response (200 OK):**
```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 0,
    "totalPages": 0
  }
}
```

✅ **Ý nghĩa:** Chưa có giao dịch nào

---

### TEST 3: Deposit - Momo Gateway

**Request:**
```
POST http://localhost:3000/wallets/deposit
Authorization: Bearer {{accessToken}}
Content-Type: application/json

{
  "amount": 500000,
  "gateway": "momo"
}
```

**Expected Response (201 Created):**
```json
{
  "transactionId": "1",
  "paymentId": "1",
  "paymentUrl": "https://test-payment.momo.vn/v2/gateway/pay?partnerCode=MOCK&orderId=1&amount=500000&returnUrl=http://localhost:3000/api/v1/payments/callback",
  "amount": 500000,
  "gateway": "momo",
  "status": "pending",
  "message": "Please complete payment at the provided URL"
}
```

✅ **Ý nghĩa:**
- Transaction được tạo với status `pending`
- Payment record được tạo với status `initiated`
- PaymentURL trả về để user thanh toán (mock URL)

**Kiểm tra DB:**
```sql
SELECT * FROM wallet_transactions WHERE wallet_user_id = 1;
SELECT * FROM payments WHERE id = 1;
```

---

### TEST 4: Withdraw - Small Amount (Auto Approve)

**Request:**
```
POST http://localhost:3000/wallets/withdraw
Authorization: Bearer {{accessToken}}

{
  "amount": 200000,
  "bankAccount": "1234567890",
  "bankName": "Vietcombank"
}
```

**Expected Response (nếu balance đủ - 201 Created):**
```json
{
  "message": "Withdrawal processed successfully",
  "transactionId": "2",
  "amount": 200000,
  "status": "completed",
  "bankAccount": "1234567890",
  "bankName": "Vietcombank"
}
```

**Expected Response (nếu balance = 0 - 400 Bad Request):**
```json
{
  "statusCode": 400,
  "message": "Insufficient balance. Available: 0 VND",
  "error": "Bad Request"
}
```

✅ **Logic:**
- Số tiền < 1M VND → Auto approve (status = `completed`)
- Balance bị trừ ngay lập tức
- Payment record tạo với status `succeeded`

---

### TEST 5: Withdraw - Large Amount (Need Approval)

**Request:**
```
POST http://localhost:3000/wallets/withdraw

{
  "amount": 5000000,
  "bankAccount": "9876543210",
  "bankName": "ACB"
}
```

**Expected Response (nếu balance đủ - 201 Created):**
```json
{
  "message": "Withdrawal request submitted for approval",
  "transactionId": "3",
  "amount": 5000000,
  "status": "pending",
  "note": "Large withdrawals require admin approval (1-2 business days)"
}
```

✅ **Logic:**
- Số tiền >= 1M VND → Cần admin approve (status = `pending`)
- Balance vẫn bị trừ ngay (để tránh double-spending)
- Admin sẽ approve/reject sau

---

## ❌ Test Validation (Expected Errors)

### TEST 6: Invalid Amount (< 100k)

**Request:**
```
POST http://localhost:3000/wallets/deposit

{
  "amount": 50000,
  "gateway": "momo"
}
```

**Expected Response (400 Bad Request):**
```json
{
  "statusCode": 400,
  "message": [
    "Minimum deposit is 100,000 VND"
  ],
  "error": "Bad Request"
}
```

✅ **Validation hoạt động:** `@Min(100000)` trong DTO

---

### TEST 7: Invalid Gateway

**Request:**
```
POST http://localhost:3000/wallets/deposit

{
  "amount": 500000,
  "gateway": "paypal"
}
```

**Expected Response (400 Bad Request):**
```json
{
  "statusCode": 400,
  "message": [
    "Gateway must be one of: momo, bank_transfer, card"
  ],
  "error": "Bad Request"
}
```

✅ **Validation hoạt động:** `@IsEnum()` trong DTO

---

### TEST 8: Daily Withdrawal Limit

Rút nhiều lần trong ngày (tổng > 10M VND):

**Expected Response (400 Bad Request):**
```json
{
  "statusCode": 400,
  "message": "Daily withdrawal limit exceeded. Limit: 10000000 VND, Used today: 5000000 VND",
  "error": "Bad Request"
}
```

✅ **Business rule:** Max 10M VND/ngày

---

## 📊 Checklist Test Cases

| # | Test Case | Method | Endpoint | Expected Result | Status |
|---|-----------|--------|----------|----------------|--------|
| 1 | Get balance (first time) | GET | `/wallets/balance` | Balance = 0 | ⬜ |
| 2 | Get empty transactions | GET | `/wallets/transactions` | Empty array | ⬜ |
| 3 | Deposit with Momo | POST | `/wallets/deposit` | Pending transaction | ⬜ |
| 4 | Deposit with Bank Transfer | POST | `/wallets/deposit` | Pending transaction | ⬜ |
| 5 | Withdraw < 1M (auto approve) | POST | `/wallets/withdraw` | Completed | ⬜ |
| 6 | Withdraw >= 1M (need approval) | POST | `/wallets/withdraw` | Pending approval | ⬜ |
| 7 | Withdraw with insufficient balance | POST | `/wallets/withdraw` | 400 Error | ⬜ |
| 8 | Deposit amount < 100k | POST | `/wallets/deposit` | 400 Validation error | ⬜ |
| 9 | Invalid gateway | POST | `/wallets/deposit` | 400 Validation error | ⬜ |
| 10 | Exceed daily limit | POST | `/wallets/withdraw` | 400 Limit error | ⬜ |
| 11 | Get transactions after operations | GET | `/wallets/transactions` | List of transactions | ⬜ |
| 12 | Unauthorized access (no token) | GET | `/wallets/balance` | 401 Unauthorized | ⬜ |

---

## 🔍 Kiểm tra Database

Sau khi test, kiểm tra data trong DB:

```sql
-- Xem wallets
SELECT * FROM wallets;

-- Xem transactions
SELECT id, wallet_user_id, type, amount, balance_after, status, created_at 
FROM wallet_transactions 
ORDER BY created_at DESC;

-- Xem payments
SELECT id, amount, method, gateway, gateway_tx_id, status, created_at 
FROM payments 
ORDER BY created_at DESC;

-- Join để xem full picture
SELECT 
    wt.id as tx_id,
    wt.type,
    wt.amount,
    wt.status as tx_status,
    p.gateway,
    p.status as payment_status,
    wt.created_at
FROM wallet_transactions wt
LEFT JOIN payments p ON p.id = wt.related_payment_id
ORDER BY wt.created_at DESC;
```

---

## 🐛 Troubleshooting

### Lỗi 401 Unauthorized
- Token hết hạn → Login lại để lấy token mới
- Token không được set → Kiểm tra Test Script trong Login request

### Lỗi 404 Not Found
- Backend chưa chạy → Check terminal: `pnpm start:dev`
- URL sai → Check `http://localhost:3000`

### Lỗi 500 Internal Server Error
- Database chưa chạy → Check Docker: `docker ps`
- Migrations chưa run → Run: `pnpm prisma:migrate`

---

## ✅ Kết quả mong đợi

Sau khi test xong:
- ✅ User có wallet với balance đã thay đổi
- ✅ Có nhiều transactions trong DB
- ✅ Payments được tạo và link với transactions
- ✅ Validations hoạt động chính xác
- ✅ Business rules (auto-approve, daily limit) hoạt động

**Happy Testing! 🎉**
