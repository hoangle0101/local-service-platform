# Implementation Plan - Member 3 (Finance & Operations)

**Nhiệm vụ:** Implement Payment, Wallet, Interaction (Chat/Dispute), và Admin modules.

**⚠️ UPDATED:** Blockchain feature removed - Now 33 endpoints (was 35)

---

## 📊 Overview

| Module        | Endpoints | Difficulty   |
| ------------- | --------- | ------------ |
| Wallets       | 4         | ⭐⭐⭐       |
| Payments      | 2         | ⭐⭐⭐⭐     |
| Conversations | 5         | ⭐⭐         |
| Disputes      | 4         | ⭐⭐⭐       |
| Admin         | 18        | ⭐⭐⭐⭐     |
| **Total**     | **33**    | **⭐⭐⭐⭐** |

---

## 1. Module Wallets (`src/modules/wallets`)

### A. DTOs (`dto/wallet.dto.ts`)

```typescript
import {
  IsNotEmpty,
  IsNumber,
  IsString,
  IsEnum,
  Min,
  Max,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class DepositDto {
  @ApiProperty({ example: 500000 })
  @IsNotEmpty()
  @IsNumber()
  @Min(100000) // Min 100k VND
  amount: number;

  @ApiProperty({ enum: ["momo", "stripe", "bank_transfer"] })
  @IsEnum(["momo", "stripe", "bank_transfer"])
  gateway: string;
}

export class WithdrawDto {
  @ApiProperty({ example: 200000 })
  @IsNotEmpty()
  @IsNumber()
  @Min(100000) // Min 100k VND
  @Max(10000000) // Max 10M VND per transaction
  amount: number;

  @ApiProperty({ example: "1234567890" })
  @IsNotEmpty()
  @IsString()
  bankAccount: string;

  @ApiProperty({ example: "Vietcombank" })
  @IsNotEmpty()
  @IsString()
  bankName: string;
}
```

### B. Service Implementation (`wallets.service.ts`)

#### **1. Get Balance**

```typescript
async getBalance(userId: bigint) {
  const wallet = await this.prisma.wallet.findUnique({
    where: { userId },
    include: {
      _count: {
        select: { transactions: true }
      }
    }
  });

  if (!wallet) {
    throw new NotFoundException('Wallet not found');
  }

  return {
    balance: wallet.balance.toString(),
    currency: wallet.currency,
    totalTransactions: wallet._count.transactions
  };
}
```

#### **2. Get Transaction History**

```typescript
async getTransactions(userId: bigint, query: PaginationDto) {
  const wallet = await this.prisma.wallet.findUnique({
    where: { userId }
  });

  if (!wallet) {
    throw new NotFoundException('Wallet not found');
  }

  const skip = (query.page - 1) * query.limit;

  const [transactions, total] = await Promise.all([
    this.prisma.walletTransaction.findMany({
      where: { walletId: wallet.userId },
      skip,
      take: query.limit,
      orderBy: { createdAt: 'desc' }
    }),
    this.prisma.walletTransaction.count({
      where: { walletId: wallet.userId }
    })
  ]);

  return {
    transactions,
    meta: {
      total,
      page: query.page,
      limit: query.limit,
      totalPages: Math.ceil(total / query.limit)
    }
  };
}
```

#### **3. Deposit (Trigger Payment)**

```typescript
async deposit(userId: bigint, dto: DepositDto) {
  const wallet = await this.prisma.wallet.findUnique({
    where: { userId }
  });

  if (!wallet) {
    throw new NotFoundException('Wallet not found');
  }

  return this.prisma.$transaction(async (tx) => {
    // Create wallet transaction (pending)
    const transaction = await tx.walletTransaction.create({
      data: {
        walletId: wallet.userId,
        type: 'deposit',
        amount: dto.amount,
        status: 'pending',
        description: `Deposit via ${dto.gateway}`,
        metadata: {}
      }
    });

    // Create payment record
    const payment = await tx.payment.create({
      data: {
        bookingId: null,
        amount: dto.amount,
        currency: 'VND',
        method: dto.gateway === 'momo' ? 'momo' :
                dto.gateway === 'stripe' ? 'card' : 'bank_transfer',
        gateway: dto.gateway,
        gatewayTxId: `pending_${Date.now()}`,
        status: 'initiated',
        payload: {
          transactionId: transaction.id.toString(),
          type: 'deposit'
        }
      }
    });

    // Generate payment URL (mock for now)
    // TODO: Integrate with real payment gateway
    const paymentUrl = this.generatePaymentUrl(payment.id, dto.gateway, dto.amount);

    return {
      transactionId: transaction.id.toString(),
      paymentId: payment.id.toString(),
      paymentUrl,
      amount: dto.amount,
      gateway: dto.gateway
    };
  });
}

private generatePaymentUrl(paymentId: bigint, gateway: string, amount: number): string {
  // Mock payment URL
  // In production: Call Momo/Stripe API to get real payment URL
  const baseUrl = process.env.APP_URL || 'http://localhost:3000';
  return `${baseUrl}/api/v1/payments/checkout/${paymentId}?gateway=${gateway}&amount=${amount}`;
}
```

#### **4. Withdraw (với Approval Process)**

```typescript
async withdraw(userId: bigint, dto: WithdrawDto) {
  const wallet = await this.prisma.wallet.findUnique({
    where: { userId }
  });

  if (!wallet) {
    throw new NotFoundException('Wallet not found');
  }

  // Check balance
  if (wallet.balance < dto.amount) {
    throw new BadRequestException('Insufficient balance');
  }

  // Check daily limit
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const todayWithdrawals = await this.prisma.walletTransaction.aggregate({
    where: {
      walletId: wallet.userId,
      type: 'withdraw',
      createdAt: { gte: today }
    },
    _sum: { amount: true }
  });

  const dailyLimit = 10000000; // 10M VND
  const totalToday = Number(todayWithdrawals._sum.amount) || 0;

  if (totalToday + dto.amount > dailyLimit) {
    throw new BadRequestException(`Daily withdrawal limit exceeded (${dailyLimit} VND)`);
  }

  return this.prisma.$transaction(async (tx) => {
    // Deduct balance immediately
    await tx.wallet.update({
      where: { userId: wallet.userId },
      data: { balance: { decrement: dto.amount } }
    });

    // Create withdrawal transaction
    const transaction = await tx.walletTransaction.create({
      data: {
        walletId: wallet.userId,
        type: 'withdraw',
        amount: dto.amount,
        status: 'pending', // Pending admin approval
        description: `Withdrawal to ${dto.bankName}`,
        metadata: {
          bankAccount: dto.bankAccount,
          bankName: dto.bankName
        }
      }
    });

    // Auto-approve if < 1M VND
    if (dto.amount < 1000000) {
      await tx.walletTransaction.update({
        where: { id: transaction.id },
        data: { status: 'completed' }
      });

      // Create payout payment
      await tx.payment.create({
        data: {
          bookingId: null,
          amount: dto.amount,
          currency: 'VND',
          method: 'bank_transfer',
          gateway: 'bank_transfer',
          gatewayTxId: `payout_${Date.now()}`,
          status: 'succeeded',
          payload: {
            transactionId: transaction.id.toString(),
            bankAccount: dto.bankAccount,
            type: 'payout'
          }
        }
      });

      return {
        message: 'Withdrawal processed successfully',
        transactionId: transaction.id.toString(),
        status: 'completed'
      };
    }

    // Require admin approval for >= 1M
    return {
      message: 'Withdrawal request submitted for approval',
      transactionId: transaction.id.toString(),
      status: 'pending'
    };
  });
}
```

### C. Controller (`wallets.controller.ts`)

```typescript
import { Controller, Get, Post, Body, Query, UseGuards } from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { WalletsService } from "./wallets.service";
import { DepositDto, WithdrawDto } from "./dto/wallet.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("Wallets")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("wallets")
export class WalletsController {
  constructor(private walletsService: WalletsService) {}

  @Get("me")
  @ApiOperation({ summary: "Get wallet balance" })
  async getBalance(@CurrentUser() user: any) {
    return this.walletsService.getBalance(BigInt(user.userId));
  }

  @Get("transactions")
  @ApiOperation({ summary: "Get transaction history" })
  async getTransactions(@CurrentUser() user: any, @Query() query: any) {
    return this.walletsService.getTransactions(BigInt(user.userId), query);
  }

  @Post("deposit")
  @ApiOperation({ summary: "Deposit to wallet" })
  async deposit(@CurrentUser() user: any, @Body() dto: DepositDto) {
    return this.walletsService.deposit(BigInt(user.userId), dto);
  }

  @Post("withdraw")
  @ApiOperation({ summary: "Withdraw from wallet" })
  async withdraw(@CurrentUser() user: any, @Body() dto: WithdrawDto) {
    return this.walletsService.withdraw(BigInt(user.userId), dto);
  }
}
```

---

## 2. Module Payments (`src/modules/payments`)

### A. DTOs (`dto/payment.dto.ts`)

```typescript
export class CheckoutDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsNumber()
  bookingId: number;

  @ApiProperty({ enum: ["wallet", "momo", "stripe"] })
  @IsEnum(["wallet", "momo", "stripe"])
  paymentMethod: string;
}

export class WebhookDto {
  // Gateway-specific fields
  // Will be validated based on gateway signature
}
```

### B. Service Implementation (`payments.service.ts`)

#### **1. Checkout Booking**

```typescript
async checkout(userId: bigint, dto: CheckoutDto) {
  const booking = await this.prisma.booking.findUnique({
    where: { id: BigInt(dto.bookingId) },
    include: { customer: { include: { wallet: true } } }
  });

  if (!booking || booking.customerId !== userId) {
    throw new NotFoundException('Booking not found');
  }

  if (booking.paymentStatus === 'paid') {
    throw new BadRequestException('Booking already paid');
  }

  // Wallet payment
  if (dto.paymentMethod === 'wallet') {
    const wallet = booking.customer.wallet;

    if (wallet.balance < booking.totalAmount) {
      throw new BadRequestException('Insufficient wallet balance');
    }

    return this.prisma.$transaction(async (tx) => {
      // Deduct from wallet
      await tx.wallet.update({
        where: { userId: wallet.userId },
        data: { balance: { decrement: booking.totalAmount } }
      });

      // Create wallet transaction
      await tx.walletTransaction.create({
        data: {
          walletId: wallet.userId,
          type: 'payment',
          amount: booking.totalAmount,
          status: 'completed',
          description: `Payment for booking #${booking.id}`,
          metadata: {}
        }
      });

      // Create payment record
      const payment = await tx.payment.create({
        data: {
          bookingId: booking.id,
          amount: booking.totalAmount,
          currency: 'VND',
          method: 'wallet',
          gateway: 'wallet',
          gatewayTxId: `wallet_${Date.now()}`,
          status: 'succeeded',
          payload: {}
        }
      });

      // Update booking
      await tx.booking.update({
        where: { id: booking.id },
        data: { paymentStatus: 'paid' }
      });

      return {
        message: 'Payment successful',
        paymentId: payment.id.toString()
      };
    });
  }

  // Gateway payment (Momo/Stripe)
  return this.prisma.$transaction(async (tx) => {
    const payment = await tx.payment.create({
      data: {
        bookingId: booking.id,
        amount: booking.totalAmount,
        currency: 'VND',
        method: dto.paymentMethod === 'momo' ? 'momo' : 'card',
        gateway: dto.paymentMethod,
        gatewayTxId: `pending_${Date.now()}`,
        status: 'initiated',
        payload: {}
      }
    });

    // Generate payment URL
    const paymentUrl = this.generatePaymentUrl(payment.id, dto.paymentMethod, booking.totalAmount);

    return {
      paymentId: payment.id.toString(),
      paymentUrl,
      amount: booking.totalAmount.toString()
    };
  });
}

private generatePaymentUrl(paymentId: bigint, gateway: string, amount: number): string {
  // TODO: Integrate with real payment gateway
  const baseUrl = process.env.APP_URL || 'http://localhost:3000';
  return `${baseUrl}/api/v1/payments/checkout/${paymentId}?gateway=${gateway}&amount=${amount}`;
}
```

#### **2. Payment Webhook (Critical!)**

```typescript
async handleWebhook(gateway: string, body: any, signature: string) {
  // 1. Verify signature
  const isValid = this.verifyWebhookSignature(gateway, body, signature);
  if (!isValid) {
    throw new UnauthorizedException('Invalid webhook signature');
  }

  // 2. Extract payment info (gateway-specific)
  const { transactionId, status, amount } = this.parseWebhookData(gateway, body);

  // 3. Find payment
  const payment = await this.prisma.payment.findFirst({
    where: {
      gatewayTxId: transactionId,
      gateway
    },
    include: { booking: true }
  });

  if (!payment) {
    console.error(`Payment not found: ${transactionId}`);
    return { message: 'Payment not found' };
  }

  // 4. Check idempotency (prevent double processing)
  if (payment.status === 'succeeded') {
    console.log(`Payment already processed: ${transactionId}`);
    return { message: 'Already processed' };
  }

  // 5. Process based on status
  if (status === 'success') {
    await this.processSuccessfulPayment(payment);
  } else if (status === 'failed') {
    await this.processFailedPayment(payment);
  }

  // 6. Log to audit
  await this.prisma.auditLog.create({
    data: {
      actorUserId: null,
      action: 'payment_webhook',
      objectType: 'payment',
      objectId: payment.id,
      detail: {
        gateway,
        transactionId,
        status,
        amount
      }
    }
  });

  return { message: 'Webhook processed' };
}

private async processSuccessfulPayment(payment: any) {
  return this.prisma.$transaction(async (tx) => {
    // Update payment status
    await tx.payment.update({
      where: { id: payment.id },
      data: { status: 'succeeded' }
    });

    // If deposit: Update wallet
    if (payment.payload?.type === 'deposit') {
      const transactionId = BigInt(payment.payload.transactionId);

      const transaction = await tx.walletTransaction.findUnique({
        where: { id: transactionId }
      });

      if (transaction) {
        await tx.walletTransaction.update({
          where: { id: transaction.id },
          data: { status: 'completed' }
        });

        await tx.wallet.update({
          where: { userId: transaction.walletId },
          data: { balance: { increment: payment.amount } }
        });
      }
    }

    // If booking: Update booking
    if (payment.bookingId) {
      await tx.booking.update({
        where: { id: payment.bookingId },
        data: { paymentStatus: 'paid' }
      });

      // Notify provider
      const booking = await tx.booking.findUnique({
        where: { id: payment.bookingId }
      });

      await tx.notification.create({
        data: {
          userId: booking.providerId,
          title: 'Payment Received',
          body: `Payment received for booking #${booking.id}`,
          type: 'payment',
          data: { bookingId: booking.id.toString() },
          isRead: false
        }
      });
    }

    // Notify user
    await tx.notification.create({
      data: {
        userId: payment.booking?.customerId || BigInt(1),
        title: 'Payment Successful',
        body: `Your payment of ${payment.amount} VND was successful`,
        type: 'payment',
        data: { paymentId: payment.id.toString() },
        isRead: false
      }
    });
  });
}

private async processFailedPayment(payment: any) {
  await this.prisma.payment.update({
    where: { id: payment.id },
    data: { status: 'failed' }
  });

  // Notify user
  await this.prisma.notification.create({
    data: {
      userId: payment.booking?.customerId || BigInt(1),
      title: 'Payment Failed',
      body: `Your payment of ${payment.amount} VND failed`,
      type: 'payment',
      data: { paymentId: payment.id.toString() },
      isRead: false
    }
  });
}

private verifyWebhookSignature(gateway: string, body: any, signature: string): boolean {
  // TODO: Implement signature verification
  // Momo: HMAC SHA256
  // Stripe: stripe.webhooks.constructEvent

  if (process.env.NODE_ENV === 'development') {
    return true; // Skip verification in dev
  }

  // Production implementation
  const secret = process.env[`${gateway.toUpperCase()}_WEBHOOK_SECRET`];
  // ... verify signature

  return true;
}

private parseWebhookData(gateway: string, body: any): any {
  // Parse gateway-specific webhook data
  if (gateway === 'momo') {
    return {
      transactionId: body.orderId,
      status: body.resultCode === 0 ? 'success' : 'failed',
      amount: body.amount
    };
  }

  if (gateway === 'stripe') {
    return {
      transactionId: body.data.object.id,
      status: body.data.object.status === 'succeeded' ? 'success' : 'failed',
      amount: body.data.object.amount / 100
    };
  }

  throw new BadRequestException('Unsupported gateway');
}
```

### C. Controller (`payments.controller.ts`)

```typescript
@ApiTags("Payments")
@Controller("payments")
export class PaymentsController {
  constructor(private paymentsService: PaymentsService) {}

  @Post("checkout")
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Checkout booking" })
  async checkout(@CurrentUser() user: any, @Body() dto: CheckoutDto) {
    return this.paymentsService.checkout(BigInt(user.userId), dto);
  }

  @Post("webhook/:gateway")
  @ApiOperation({ summary: "Payment webhook" })
  async webhook(
    @Param("gateway") gateway: string,
    @Body() body: any,
    @Headers("signature") signature: string
  ) {
    return this.paymentsService.handleWebhook(gateway, body, signature);
  }
}
```

---

## 3. Module Conversations (`src/modules/conversations`)

### A. DTOs

```typescript
export class CreateConversationDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsNumber()
  bookingId: number;
}

export class SendMessageDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  content: string;

  @ApiPropertyOptional({ enum: ["text", "image", "file"] })
  @IsOptional()
  @IsEnum(["text", "image", "file"])
  type?: string = "text";

  @ApiPropertyOptional()
  @IsOptional()
  attachmentUrl?: string;
}
```

### B. Service Implementation

```typescript
async createConversation(userId: bigint, dto: CreateConversationDto) {
  const booking = await this.prisma.booking.findUnique({
    where: { id: BigInt(dto.bookingId) }
  });

  if (!booking) {
    throw new NotFoundException('Booking not found');
  }

  // Verify user is part of booking
  if (booking.customerId !== userId && booking.providerId !== userId) {
    throw new ForbiddenException('Access denied');
  }

  // Check if conversation exists
  const existing = await this.prisma.conversation.findFirst({
    where: { bookingId: BigInt(dto.bookingId) }
  });

  if (existing) {
    return existing;
  }

  // Create conversation
  return this.prisma.conversation.create({
    data: {
      bookingId: BigInt(dto.bookingId),
      participants: [booking.customerId.toString(), booking.providerId.toString()],
      lastMessageAt: new Date(),
      unreadCount: 0
    }
  });
}

async sendMessage(userId: bigint, conversationId: bigint, dto: SendMessageDto) {
  const conversation = await this.prisma.conversation.findUnique({
    where: { id: conversationId }
  });

  if (!conversation) {
    throw new NotFoundException('Conversation not found');
  }

  // Verify user is participant
  const participants = conversation.participants as string[];
  if (!participants.includes(userId.toString())) {
    throw new ForbiddenException('Not a participant');
  }

  return this.prisma.$transaction(async (tx) => {
    // Create message
    const message = await tx.message.create({
      data: {
        conversationId,
        senderId: userId,
        content: dto.content,
        type: dto.type || 'text',
        attachmentUrl: dto.attachmentUrl
      }
    });

    // Update conversation
    await tx.conversation.update({
      where: { id: conversationId },
      data: {
        lastMessageAt: new Date(),
        unreadCount: { increment: 1 }
      }
    });

    // Notify other participant
    const recipientId = participants.find(p => p !== userId.toString());
    await tx.notification.create({
      data: {
        userId: BigInt(recipientId),
        title: 'New Message',
        body: dto.content.substring(0, 50),
        type: 'message',
        data: {
          conversationId: conversationId.toString(),
          messageId: message.id.toString()
        },
        isRead: false
      }
    });

    return message;
  });
}
```

### C. Controller

```typescript
@ApiTags("Conversations")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("conversations")
export class ConversationsController {
  constructor(private conversationsService: ConversationsService) {}

  @Get()
  @ApiOperation({ summary: "List conversations" })
  async findAll(@CurrentUser() user: any) {
    return this.conversationsService.findAll(BigInt(user.userId));
  }

  @Post()
  @ApiOperation({ summary: "Create conversation" })
  async create(@CurrentUser() user: any, @Body() dto: CreateConversationDto) {
    return this.conversationsService.createConversation(
      BigInt(user.userId),
      dto
    );
  }

  @Get(":id/messages")
  @ApiOperation({ summary: "Get messages" })
  async getMessages(@CurrentUser() user: any, @Param("id") id: string) {
    return this.conversationsService.getMessages(
      BigInt(user.userId),
      BigInt(id)
    );
  }

  @Post(":id/messages")
  @ApiOperation({ summary: "Send message" })
  async sendMessage(
    @CurrentUser() user: any,
    @Param("id") id: string,
    @Body() dto: SendMessageDto
  ) {
    return this.conversationsService.sendMessage(
      BigInt(user.userId),
      BigInt(id),
      dto
    );
  }

  @Patch(":id/read")
  @ApiOperation({ summary: "Mark as read" })
  async markAsRead(@CurrentUser() user: any, @Param("id") id: string) {
    return this.conversationsService.markAsRead(
      BigInt(user.userId),
      BigInt(id)
    );
  }
}
```

---

## 4. Module Disputes (`src/modules/disputes`)

### A. Service Implementation

```typescript
async createDispute(userId: bigint, dto: CreateDisputeDto) {
  const booking = await this.prisma.booking.findUnique({
    where: { id: BigInt(dto.bookingId) }
  });

  if (!booking || booking.customerId !== userId) {
    throw new NotFoundException('Booking not found');
  }

  // Can only dispute completed bookings
  if (booking.status !== 'completed') {
    throw new BadRequestException('Can only dispute completed bookings');
  }

  // Check if already disputed
  const existing = await this.prisma.dispute.findFirst({
    where: { bookingId: BigInt(dto.bookingId) }
  });

  if (existing) {
    throw new BadRequestException('Dispute already exists');
  }

  return this.prisma.dispute.create({
    data: {
      bookingId: BigInt(dto.bookingId),
      raisedBy: userId,
      reason: dto.reason,
      description: dto.description,
      status: 'open',
      evidence: dto.evidence || []
    }
  });
}
```

---

## 5. Module Admin (`src/modules/admin`)

### A. RBAC Implementation

#### **Update RolesGuard**

```typescript
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector, private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()]
    );

    if (!requiredRoles) {
      return true;
    }

    const { user } = context.switchToHttp().getRequest();

    // Get user roles from DB
    const userRoles = await this.prisma.userRole.findMany({
      where: { userId: BigInt(user.userId) },
      include: { role: true },
    });

    const roleNames = userRoles.map((ur) => ur.role.name);

    // Check if user has any of required roles
    return requiredRoles.some((role) => roleNames.includes(role));
  }
}
```

#### **Dispute Resolution**

```typescript
async resolveDispute(disputeId: bigint, adminId: bigint, dto: ResolveDisputeDto) {
  const dispute = await this.prisma.dispute.findUnique({
    where: { id: disputeId },
    include: { booking: { include: { customer: { include: { wallet: true } } } } }
  });

  if (!dispute) {
    throw new NotFoundException('Dispute not found');
  }

  return this.prisma.$transaction(async (tx) => {
    // Update dispute
    await tx.dispute.update({
      where: { id: disputeId },
      data: {
        status: 'resolved',
        resolution: dto.resolution,
        resolvedBy: adminId,
        resolvedAt: new Date(),
        adminNotes: dto.notes
      }
    });

    // Process refund if in favor of customer
    if (dto.resolution === 'customer_favor' && dto.refundAmount > 0) {
      await tx.walletTransaction.create({
        data: {
          walletId: dispute.booking.customerId,
          type: 'refund',
          amount: dto.refundAmount,
          status: 'completed',
          description: `Dispute refund for booking #${dispute.bookingId}`,
          metadata: { disputeId: disputeId.toString() }
        }
      });

      await tx.wallet.update({
        where: { userId: dispute.booking.customerId },
        data: { balance: { increment: dto.refundAmount } }
      });
    }

    // Create audit log
    await tx.auditLog.create({
      data: {
        actorUserId: adminId,
        action: 'dispute_resolved',
        objectType: 'dispute',
        objectId: disputeId,
        detail: {
          disputeId: disputeId.toString(),
          resolution: dto.resolution,
          refundAmount: dto.refundAmount
        }
      }
    });

    return { message: 'Dispute resolved successfully' };
  });
}
```

---

## 6. Verification Plan

### Test Scenarios:

**Wallet:**

1. Deposit 500k → Check payment URL
2. Mock webhook success → Verify balance increased
3. Withdraw 200k → Verify auto-approved
4. Withdraw 5M → Verify pending approval

**Payment:**

1. Checkout booking with wallet
2. Checkout with Momo → Get payment URL
3. Simulate webhook → Verify booking paid

**Chat:**

1. Create conversation
2. Send messages
3. Mark as read

**Admin:**

1. List users
2. Ban user
3. Resolve dispute
4. Create role/permission

---

**Estimated Time:** 7.5 days (was 8 days)  
**Difficulty:** ⭐⭐⭐⭐ (Hard - Complex integrations)

**Total Endpoints:** 33 (Wallets: 4, Payments: 2, Conversations: 5, Disputes: 4, Admin: 18)
