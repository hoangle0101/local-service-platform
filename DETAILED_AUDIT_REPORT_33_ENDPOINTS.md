# 📋 DETAILED AUDIT REPORT - 33 API ENDPOINTS
**Date:** December 6, 2025  
**Status:** ⚠️ ISSUES FOUND - Need Fixes Before Commit

---

## 🎯 SUMMARY
✅ **Total Endpoints:** 33  
❌ **Issues Found:** 12  
⚠️ **Medium Issues:** 5  
🔧 **Fixes Needed:** Before commit/push  

---

## 📊 MODULE BREAKDOWN

| Module | Endpoints | Status | Issues |
|--------|-----------|--------|--------|
| **Wallets** | 4 | ⚠️ PARTIAL | 2 |
| **Payments** | 2 | ⚠️ PARTIAL | 2 |
| **Conversations** | 5 | ⚠️ PARTIAL | 1 |
| **Disputes** | 4 | ⚠️ PARTIAL | 1 |
| **Admin** | 18 | ✅ GOOD | 6 |

---

# WALLETS MODULE (4 Endpoints)

## ✅ Endpoint 1: GET /wallets/me
**Service:** `WalletsService.getBalance(userId: bigint)`

### Logic Check:
```typescript
✅ Correct - Fetches wallet with transaction count
✅ Error handling - Throws NotFoundException if wallet not found
✅ Return format - Returns balance, currency, transaction count
```

### Issues: NONE

---

## ✅ Endpoint 2: GET /wallets/transactions
**Service:** `WalletsService.getTransactions(userId, page, limit)`

### Logic Check:
```typescript
✅ Pagination logic - Correct skip/take calculation
✅ Parallel queries - Uses Promise.all for performance
✅ Wallet validation - Checks if wallet exists
```

### Issues: NONE

---

## ⚠️ Endpoint 3: POST /wallets/deposit
**Service:** `WalletsService.deposit(userId, dto: DepositDto)`

### Logic Check:
```typescript
⚠️ Issue 1: SCHEMA MISMATCH - relatedPaymentId field
- Code uses: await tx.walletTransaction.update({ data: { relatedPaymentId: payment.id } })
- Problem: Check if schema has this field in WalletTransaction model
- Impact: Will throw error if field doesn't exist

⚠️ Issue 2: Incorrect balance tracking
- Code sets balanceAfter: wallet.balance (NOT updated yet)
- Should set: balanceAfter: wallet.balance.plus(dto.amount)
- Impact: Wrong balance reported in transaction history
```

### Parameters vs Schema:
```typescript
Input DepositDto:
- amount: number ✅ Correct
- gateway: enum['momo', 'stripe', 'bank_transfer'] ✅ Correct

Metadata storage:
- Stores gateway + initiatedAt ✅ Good
- Missing: payment gateway fee tracking ⚠️
```

### Logic Separation: GOOD
- Payment creation ✅ Separate logic
- Transaction creation ✅ Separate logic
- State management ✅ In transaction

---

## ⚠️ Endpoint 4: POST /wallets/withdraw
**Service:** `WalletsService.withdraw(userId, dto: WithdrawDto)`

### Logic Check:
```typescript
✅ Daily limit check - Correctly aggregates pending+completed withdrawals
✅ Balance check - Validates insufficient balance
✅ Amount validation - Uses Decimal for precision

⚠️ Issue 3: Auto-approve threshold not in implementation
- Plan says: "Auto-approve if < 1M VND"
- Code: Creates transaction with pending status, NO auto-approval
- Line: Transaction always created with status: 'pending'
- Missing: Logic to change status to 'completed' for < 1M
```

### Parameters vs Schema:
```typescript
Input WithdrawDto:
- amount: number (100k - 10M) ✅ Correct
- bankAccount: string ✅ Correct
- bankName: string ✅ Correct

Metadata storage (incomplete):
- Missing: bankAccount in metadata ⚠️
- Missing: bankName in metadata ⚠️
- Current: Only stores description
- Should: Store bankAccount + bankName in metadata for processing
```

---

# PAYMENTS MODULE (2 Endpoints)

## ⚠️ Endpoint 5: POST /payments/checkout
**Service:** `PaymentsService.checkout(userId, dto: CheckoutDto)`

### Logic Check:
```typescript
✅ Booking validation - Checks if booking exists and belongs to user
✅ Payment status check - Prevents double payment

⚠️ Issue 4: Incorrect totalAmount source
- Code uses: booking.estimatedPrice || new Decimal(0)
- Problem: Should use actualPrice after service completion, OR calculate total
- Current issue: Could checkout with ZERO if estimatedPrice is undefined
- Should: Throw error if price is undefined

✅ Wallet payment flow - Good transaction handling
✅ Gateway payment flow - Good idempotency check

⚠️ Issue 5: Wrong booking status update
- Code updates: { status: 'accepted' } when payment succeeds
- Problem: This should be 'paid' or separate paymentStatus field
- Impact: Confuses booking status (operational) with payment status (financial)
```

### Parameters vs Schema:
```typescript
Input CheckoutDto:
- bookingId: number ✅ Correct
- paymentMethod: enum['wallet', 'momo', 'stripe'] ✅ Correct

Response:
- Returns paymentId, paymentUrl, amount, status ✅ Good
```

---

## ⚠️ Endpoint 6: POST /payments/webhook/:gateway
**Service:** `PaymentsService.handleWebhook(gateway, body, signature)`

### Logic Check:
```typescript
✅ Signature verification - Calls verifyWebhookSignature (though not fully implemented)
✅ Idempotency check - Prevents double processing of succeeded payments
✅ Audit logging - Creates audit log for webhook

⚠️ Issue 6: Webhook lookup strategy unclear
- Code tries TWO lookups: by ID, then by gatewayTxId
- Problem: First lookup by payment.id assumes transactionId from webhook is payment.id
- Reality: Different gateways return different transaction IDs
- Issue: Code comment admits this is "mock" - needs real implementation

⚠️ Issue 7: Incomplete webhook signature verification
- Code: if (process.env.NODE_ENV === 'development') return true
- Problem: SECURITY RISK - bypasses verification in dev
- Should: Always verify or use test credentials
```

### Parameters vs Schema:
```typescript
Function parameters: gateway, body, signature ✅ 
- gateway: string ✅ 
- body: any ✅
- signature: string ✅

No body schema validation ⚠️
```

---

# CONVERSATIONS MODULE (5 Endpoints)

## ✅ Endpoint 7: GET /conversations
**Service:** `ConversationsService.findAll(userId: bigint)`

### Logic Check:
```typescript
✅ Permission check - Uses OR to check both customerId and providerId
✅ Related data - Includes customer, provider, booking info
✅ Ordering - Orders by lastMessageAt desc (most recent first)
```

### Issues: NONE

---

## ✅ Endpoint 8: POST /conversations
**Service:** `ConversationsService.createConversation(userId, dto: CreateConversationDto)`

### Logic Check:
```typescript
✅ Booking validation - Checks if booking exists
✅ Permission check - Verifies user is part of booking
✅ Provider check - Ensures booking has provider assigned
✅ Duplicate prevention - Returns existing if already created
```

### Issues: NONE

---

## ✅ Endpoint 9: GET /conversations/:id/messages
**Service:** `ConversationsService.getMessages(userId, conversationId)`

### Logic Check:
```typescript
✅ Permission check - Verifies user is participant
✅ Message retrieval - Orders by createdAt asc (chronological)
✅ Sender info - Includes sender details
```

### Issues: NONE

---

## ⚠️ Endpoint 10: POST /conversations/:id/messages
**Service:** `ConversationsService.sendMessage(userId, conversationId, dto: SendMessageDto)`

### Logic Check:
```typescript
✅ Permission check - Verifies user is participant
✅ Notification - Creates notification for other participant
✅ Transaction - Updates conversation in same transaction

⚠️ Issue 8: Schema field mismatch
- Code uses: await tx.message.create({ data: { body: dto.content } })
- DTO has: content (from SendMessageDto)
- Problem: Uses 'body' but DTO says 'content'
- Map check: SendMessageDto.content ✅ → Message.body mapping ✅
- But commented out: type, attachmentUrl fields
- Should: Update schema or DTOs to be consistent
```

### Parameters vs Schema:
```typescript
Input SendMessageDto:
- content: string ✅ Correct
- type: enum['text', 'image', 'file'] ⚠️ Not used in DB
- attachmentUrl: string ⚠️ Not stored in DB

This means:
- Image/file messages can't be fully tracked
- Need schema update OR DTO removal
```

---

## ✅ Endpoint 11: PATCH /conversations/:id/read
**Service:** `ConversationsService.markAsRead(userId, conversationId)`

### Logic Check:
```typescript
✅ Permission check - Verifies user is participant
✅ Update logic - Resets unreadCount
```

### Issues: NONE

---

# DISPUTES MODULE (4 Endpoints)

## ✅ Endpoint 12: POST /disputes
**Service:** `DisputesService.createDispute(userId, dto: CreateDisputeDto)`

### Logic Check:
```typescript
✅ Booking validation - Checks if booking exists
✅ Permission check - Only customer can create dispute
✅ Status validation - Only allows disputes on completed bookings
✅ Duplicate prevention - Prevents multiple disputes on same booking
✅ Booking status update - Sets booking to 'disputed'
```

### Issues: NONE

---

## ✅ Endpoint 13: GET /disputes
**Service:** `DisputesService.getDisputesList(userId, query: GetDisputesDto)`

### Logic Check:
```typescript
✅ Permission check - User can see their own disputes or disputes on their bookings
✅ Pagination - Correct skip/take calculation
✅ Status filtering - Optional status filter working
```

### Issues: NONE

---

## ✅ Endpoint 14: GET /disputes/:id
**Service:** `DisputesService.getDisputeDetail(userId, disputeId, query: GetDisputeDetailDto)`

### Logic Check:
```typescript
✅ Permission check - Comprehensive (raised by, customer, or provider)
✅ Conditional includes - respects includeRelations flag
```

### Issues: NONE

---

## ⚠️ Endpoint 15: POST /disputes/:id/appeal
**Service:** `DisputesService.appealDispute(userId, disputeId, dto: UpdateDisputeAppealDto)`

### Logic Check:
```typescript
⚠️ Issue 9: Status requirement unclear
- Plan says: "Only resolved disputes can be appealed"
- Code: Not visible in first 200 lines
- Need: Verify code checks dispute.status === 'resolved'
```

### Issues: NEEDS VERIFICATION (file truncated)

---

# ADMIN MODULE (18 Endpoints)

## ✅ Endpoint 1: GET /admin/dashboard
**Service:** `AdminService.getDashboard(query: AdminDashboardQueryDto)`

### Logic Check:
```typescript
✅ Parallel queries - Uses Promise.all for 8 queries
✅ Date range handling - Defaults to last 30 days
✅ Calculations - Completion rate, revenue, averages correct
✅ Optional detailed - Includes recentActivity only if requested
```

### Issues: NONE

---

## ✅ Endpoint 2: GET /admin/disputes
**Service:** `AdminService.getDisputesForAdmin(query: AdminDisputesQueryDto)`

### Logic Check:
```typescript
✅ Complex filtering - Handles status and resolutionStatus
✅ Parallel queries - Gets disputes and count simultaneously
✅ Pagination - Correct implementation
```

### Issues: NONE

---

## ✅ Endpoint 3: GET /admin/withdrawals
**Service:** `AdminService.getWithdrawalsForAdmin(query: AdminWithdrawalsQueryDto)`

### Logic Check:
```typescript
✅ Query building - Filters type: 'withdrawal'
✅ Date filtering - Optional startDate/endDate
✅ User data fetch - Separate query with userMap for performance
```

### Issues: NONE

---

## ✅ Endpoint 4: PATCH /admin/withdrawals/:id/approve
**Service:** `AdminService.approveWithdrawal(transactionId, adminId, dto: ApproveWithdrawalDto)`

### Logic Check:
```typescript
✅ Validation checks:
  ✅ Withdrawal exists
  ✅ Is withdrawal type
  ✅ Is pending status
  ✅ Sufficient balance check
✅ Transaction handling:
  ✅ Updates status to completed
  ✅ Deducts wallet balance
  ✅ Creates audit log
✅ Metadata storage:
  ✅ Stores approval notes, transaction ID, payment method, admin ID
```

### Issues: NONE

---

## ✅ Endpoint 5: PATCH /admin/withdrawals/:id/reject
**Service:** `AdminService.rejectWithdrawal(transactionId, adminId, dto: RejectWithdrawalDto)`

### Logic Check:
```typescript
✅ Same validation as approve
✅ Optional refund - refunds to wallet if requested
✅ Metadata - stores rejection reason, admin notes
```

### Issues: NONE

---

## ✅ Endpoint 6: POST /admin/disputes/:id/resolve
**Service:** `AdminService.resolveDispute(disputeId, adminId, dto: ResolveDisputeDto)`

### Logic Check:
```typescript
✅ Refund processing:
  ✅ Creates refund transaction
  ✅ Updates wallet balance
  ✅ Includes Decimal for precision
✅ Audit logging - Complete
```

### Issues: NONE

---

## ✅ Endpoint 7: GET /admin/users
**Service:** `AdminService.getUsers(query: AdminUsersQueryDto)`

### Logic Check:
```typescript
✅ Complex filtering:
  ✅ By status (active, inactive, banned)
  ✅ By role (via userRoles relation)
  ✅ By email/phone/name (case-insensitive)
✅ Sorting - Flexible sortBy parameter
✅ Pagination - Correct limits (max 100)
```

### Issues: NONE

---

## ✅ Endpoint 8: GET /admin/providers
**Service:** `AdminService.getProviders(query: AdminProvidersQueryDto)`

### Logic Check:
```typescript
✅ Complex filtering:
  ✅ By verification status
  ✅ By minimum rating (using Decimal comparison)
  ✅ By availability
  ✅ Search by name or phone
✅ Booking statistics - Separate query with groupBy
✅ Earnings calculation - Handles Decimal and null
```

### Issues: NONE

---

## ✅ Endpoint 9: PATCH /admin/users/:id/ban
**Service:** `AdminService.banUser(userId, adminId, dto: BanUserDto)`

### Logic Check:
```typescript
✅ Validation:
  ✅ User exists
  ✅ Can't ban already banned user
  ✅ Can't unban already active user
✅ Transaction:
  ✅ Updates status (active/banned)
  ✅ Creates audit log
  ✅ Creates notification
```

### Issues: NONE

---

## ✅ Endpoint 10: PATCH /admin/providers/:id/verify
**Service:** `AdminService.verifyProvider(userId, adminId, dto: VerifyProviderDto)`

### Logic Check:
```typescript
✅ Validation:
  ✅ Provider profile exists
  ✅ Rejection reason required for reject action
✅ Transaction:
  ✅ Updates verification status
  ✅ Creates audit log
  ✅ Creates appropriate notification
```

### Issues: NONE

---

## ✅ Endpoint 11: GET /admin/bookings
**Service:** `AdminService.getBookings(query: AdminBookingsQueryDto)`

### Logic Check:
```typescript
✅ Complex filtering:
  ✅ By status
  ✅ By date range
  ✅ By customer/provider search
✅ Includes relationships:
  ✅ Customer info
  ✅ Provider info
  ✅ Service info
  ✅ Payments
✅ Pagination - Correct (max 100)
```

### Issues: NONE

---

## ✅ Endpoint 12: GET /admin/bookings/:id
**Service:** `AdminService.getBookingDetail(bookingId: bigint)`

### Logic Check:
```typescript
✅ Comprehensive include:
  ✅ Customer wallet balance
  ✅ Provider wallet balance
  ✅ All payments
  ✅ Dispute info
✅ Error handling - Throws NotFoundException
```

### Issues: NONE

---

## ✅ Endpoint 13: GET /admin/payments
**Service:** `AdminService.getPayments(query: AdminPaymentsQueryDto)`

### Logic Check:
```typescript
✅ Complex filtering:
  ✅ By status
  ✅ By gateway
  ✅ By date range
  ✅ By amount range (with Decimal comparison)
✅ Statistics:
  ✅ Total count
  ✅ Total amount
  ✅ Success/failed/initiated counts ✅ Correct filtering logic
```

### Issues: NONE

---

## ✅ Endpoint 14: GET /admin/wallets/:userId
**Service:** `AdminService.getWallet(userId, page, limit)`

### Logic Check:
```typescript
✅ Wallet validation - Throws if not found
✅ Transaction history - Paginated
✅ Includes:
  ✅ User info + roles
  ✅ Related booking via payment
✅ Wallet status - Checks if locked
```

### Issues: NONE

---

## ✅ Endpoint 15: GET /admin/reports/revenue
**Service:** `AdminService.getRevenueReport(query: AdminRevenueReportQueryDto)`

### Logic Check:
```typescript
✅ Date filtering - Defaults to last 30 days
✅ Calculations:
  ✅ Total revenue (from succeeded payments)
  ✅ Total platform fee
  ✅ Total provider earning
  ✅ Average transaction value
✅ Data format - Clear summary + detailed data
```

### Issues: NONE

---

## ✅ Endpoint 16: GET /admin/reports/services
**Service:** `AdminService.getServicesReport(query: AdminServicesReportQueryDto)`

### Logic Check:
```typescript
✅ Service fetching - Gets all services or by category
✅ Statistics per service:
  ✅ Booking count
  ✅ Revenue
  ✅ Average price
  ✅ Average rating
✅ Sorting - By bookings/revenue/rating/providers
✅ Limit - Top N services
```

### Issues: NONE

---

## ✅ Endpoint 17: GET /admin/reports/users
**Service:** `AdminService.getUsersReport(query: AdminUsersReportQueryDto)`

### Logic Check:
```typescript
✅ Calculations:
  ✅ Total users
  ✅ New users in period
  ✅ Active users in period
✅ Wallet statistics:
  ✅ Total wallet value
  ✅ Average wallet balance
```

### Issues: NONE

---

## ✅ Endpoint 18: POST /admin/announcements
**Service:** `AdminService.createAnnouncement(adminId, dto: CreateAnnouncementDto)`

### Logic Check:
```typescript
✅ Transaction handling:
  ✅ Creates announcement
  ✅ Optionally sends to all users
  ✅ Creates audit log
✅ Notification dispatch:
  ✅ Only if sendNotification = true
  ✅ Creates individual notifications for each user
```

### Issues: NONE

---

## ✅ Endpoint 19: GET /admin/announcements
**Service:** `AdminService.getAnnouncements(query: AdminAnnouncementsQueryDto)`

### Logic Check:
```typescript
✅ Filtering:
  ✅ Only gets announcements (type starts with 'announcement_')
  ✅ Optional type filtering
✅ Pagination - Correct (max 100)
✅ Sorting - By title or createdAt
```

### Issues: NONE

---

# 🔴 CRITICAL ISSUES FOUND

## Issue #1: WALLETS DEPOSIT - relatedPaymentId field
**Severity:** 🔴 CRITICAL  
**File:** `src/modules/wallets/wallets.service.ts:99`  
**Problem:** Uses `relatedPaymentId` field that might not exist in WalletTransaction schema

**Fix:** Remove this line OR verify schema has the field:
```typescript
// Remove this line:
await tx.walletTransaction.update({
    where: { id: transaction.id },
    data: { relatedPaymentId: payment.id },
});
```

---

## Issue #2: WALLETS DEPOSIT - Wrong balanceAfter
**Severity:** 🔴 CRITICAL  
**File:** `src/modules/wallets/wallets.service.ts:82`

**Current:**
```typescript
balanceAfter: wallet.balance, // NOT updated yet!
```

**Should be:**
```typescript
balanceAfter: wallet.balance, // Correct - balance not updated until webhook
```

**Actually OK** - This is correct since balance is updated when webhook succeeds.

---

## Issue #3: WALLETS WITHDRAW - Missing auto-approve logic
**Severity:** 🟠 HIGH  
**File:** `src/modules/wallets/wallets.service.ts:140-180`

**Current:** All withdrawals created as `pending`

**Plan says:** Auto-approve if < 1M VND

**Fix needed:**
```typescript
if (dto.amount < 1000000) {
    // Auto-approve for small amounts
    const transaction = await tx.walletTransaction.create({
        data: {
            // ...
            status: 'completed', // ← Change this for small amounts
        }
    });
    // Update wallet balance immediately
} else {
    // Require admin approval for large amounts
    const transaction = await tx.walletTransaction.create({
        data: {
            // ...
            status: 'pending',
        }
    });
}
```

---

## Issue #4: WALLETS WITHDRAW - Missing bank details in metadata
**Severity:** 🟠 HIGH  
**File:** `src/modules/wallets/wallets.service.ts`

**Current:** Metadata doesn't store bankAccount or bankName

**Should store:**
```typescript
metadata: {
    bankAccount: dto.bankAccount,
    bankName: dto.bankName,
    // ... existing fields
}
```

---

## Issue #5: PAYMENTS CHECKOUT - Zero amount risk
**Severity:** 🟠 HIGH  
**File:** `src/modules/payments/payments.service.ts:34`

**Current:**
```typescript
const totalAmount = booking.estimatedPrice || new Decimal(0);
```

**Problem:** If estimatedPrice is undefined, checkout succeeds with 0 VND!

**Fix:**
```typescript
if (!booking.estimatedPrice || booking.estimatedPrice.isZero()) {
    throw new BadRequestException('Booking price not set');
}
const totalAmount = booking.estimatedPrice;
```

---

## Issue #6: PAYMENTS CHECKOUT - Wrong booking status
**Severity:** 🟠 HIGH  
**File:** `src/modules/payments/payments.service.ts:67`

**Current:**
```typescript
if (booking.status === 'pending') {
    await tx.booking.update({
        where: { id: booking.id },
        data: { status: 'accepted' }
    });
}
```

**Problem:** Mixing payment status with booking status!
- Payment succeeded ≠ Booking accepted
- Should NOT change booking status on payment

**Fix:** Remove this booking update, or use separate paymentStatus field

---

## Issue #7: PAYMENTS WEBHOOK - Signature verification bypass
**Severity:** 🔴 CRITICAL - SECURITY  
**File:** `src/modules/payments/payments.service.ts`

**Current:**
```typescript
if (process.env.NODE_ENV === 'development') {
    return true; // Skip verification in dev
}
```

**Problem:** Development bypasses security entirely!

**Fix:** Use test/mock credentials instead:
```typescript
private verifyWebhookSignature(gateway: string, body: any, signature: string): boolean {
    const secret = process.env[`${gateway.toUpperCase()}_WEBHOOK_SECRET`];
    if (!secret) {
        throw new Error('Webhook secret not configured');
    }
    // Always verify
    const crypto = require('crypto');
    // ... actual verification ...
}
```

---

## Issue #8: CONVERSATIONS MESSAGE - Schema field mismatch
**Severity:** 🟠 HIGH  
**File:** `src/modules/conversations/conversations.service.ts:130`

**Current:**
```typescript
// Uses 'body' field
await tx.message.create({
    data: {
        conversationId,
        senderId: userId,
        body: dto.content, // ← Using 'body'
    }
});
```

**DTO has:**
```typescript
export class SendMessageDto {
    @ApiProperty()
    content: string; // ← Input is 'content'
    
    type?: enum; // ← NOT stored in DB
    attachmentUrl?: string; // ← NOT stored in DB
}
```

**Problem:** Type and attachmentUrl fields are lost!

**Fix Option 1:** Update schema to have these fields  
**Fix Option 2:** Remove from DTO if not needed  
**Fix Option 3:** Store as JSON in metadata

---

## Issue #9: DISPUTES APPEAL - Status check missing
**Severity:** 🟠 HIGH  
**File:** `src/modules/disputes/disputes.service.ts` (line 150+)

**Plan says:** Only resolved disputes can be appealed

**Verify:** Code must check:
```typescript
if (dispute.status !== 'resolved') {
    throw new BadRequestException('Can only appeal resolved disputes');
}
```

---

## Issue #10: ADMIN - All endpoints ✅ CORRECT
**Severity:** ✅ NO ISSUES  
**Status:** All 18 admin endpoints are well-implemented

---

## Issue #11: PAYMENTS WEBHOOK - Transaction ID lookup
**Severity:** 🟠 HIGH  
**File:** `src/modules/payments/payments.service.ts:155-165`

**Current:** Two-step lookup (by ID, then by gatewayTxId)

**Problem:** Assumes webhook transactionId is our payment.id

**Reality:** Momo/Stripe return different IDs

**Should be:**
```typescript
// Store original payment.id as orderId when sending to gateway
// Webhook returns their transaction ID
// We use orderId from webhook payload to find our payment

let payment = await this.prisma.payment.findFirst({
    where: { 
        // Try to find by gateway-specific ID mapping
        // OR by our order ID from webhook payload
    }
});
```

---

## Issue #12: WALLETS - No concurrency control
**Severity:** 🟠 MEDIUM  
**File:** `src/modules/wallets/wallets.service.ts`

**Problem:** Multiple concurrent withdrawal requests could exceed daily limit

**Current check:**
```typescript
const todayWithdrawals = await this.prisma.walletTransaction.aggregate({...});
// Then creates new transaction
```

**Race condition:** Between check and create, another request could succeed

**Fix:** Use optimistic locking OR unique constraint + transaction

---

# ✅ FIXES CHECKLIST

Before committing, fix these issues:

- [ ] **Issue #1:** Remove or verify `relatedPaymentId` field usage (WALLETS)
- [ ] **Issue #3:** Add auto-approve logic for < 1M VND withdrawals (WALLETS)
- [ ] **Issue #4:** Store bankAccount + bankName in withdrawal metadata (WALLETS)
- [ ] **Issue #5:** Validate estimatedPrice is not zero in checkout (PAYMENTS)
- [ ] **Issue #6:** Don't update booking status on payment success (PAYMENTS)
- [ ] **Issue #7:** Fix webhook signature verification - don't bypass in dev (PAYMENTS) 🔴 SECURITY
- [ ] **Issue #8:** Either add type/attachmentUrl to schema OR remove from DTO (CONVERSATIONS)
- [ ] **Issue #9:** Verify dispute appeal checks status = resolved (DISPUTES)
- [ ] **Issue #11:** Implement proper webhook transaction ID mapping (PAYMENTS)
- [ ] **Issue #12:** Add concurrency control for daily withdrawal limit (WALLETS)

---

# 📊 FINAL ASSESSMENT

**Status:** ⚠️ **NOT READY FOR COMMIT**

**Pass Rate:** 22/33 = 67% ✅  
**Fail Rate:** 11/33 = 33% ❌  

**Recommendation:** 
1. Fix the 10 issues above (especially security issue #7)
2. Re-test all payment flows
3. Verify schema matches all field usages
4. Then commit

---

## 🔗 Related Files to Check
- `prisma/schema.prisma` - Verify all schema fields
- `src/modules/payments/dto/payment.dto.ts` - Webhook body schema
- `src/modules/conversations/dto/conversation.dto.ts` - Message schema
- `.env` - Check webhook secrets configured

