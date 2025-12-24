import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { MomoService, MomoCallbackData } from './momo.service';

const PLATFORM_FEE_PERCENT = 0.1; // 10% commission

export interface CreatePaymentDto {
  bookingId: bigint;
  amount: number;
  paymentMethod: 'COD' | 'MOMO';
}

export interface ReleasePaymentDto {
  bookingPaymentId: bigint;
}

@Injectable()
export class PaymentService {
  constructor(
    private prisma: PrismaService,
    private momoService: MomoService,
  ) {}

  /**
   * Calculate platform fee and provider amount
   */
  calculateFees(totalAmount: number): {
    platformFee: number;
    providerAmount: number;
  } {
    const platformFee = Math.round(totalAmount * PLATFORM_FEE_PERCENT);
    const providerAmount = totalAmount - platformFee;
    return { platformFee, providerAmount };
  }

  /**
   * Create booking payment (COD or MoMo)
   */
  async createBookingPayment(dto: CreatePaymentDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: dto.bookingId },
      include: { customer: true, providerUser: true },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (!booking.providerId) {
      throw new BadRequestException('Booking has no provider assigned');
    }

    // Check if payment already exists
    const existingPayment = await this.prisma.bookingPayment.findUnique({
      where: { bookingId: dto.bookingId },
    });

    if (existingPayment) {
      throw new BadRequestException('Payment already exists for this booking');
    }

    // Calculate fees
    const { platformFee, providerAmount } = this.calculateFees(dto.amount);

    // Create booking payment record
    const bookingPayment = await this.prisma.bookingPayment.create({
      data: {
        bookingId: dto.bookingId,
        customerId: booking.customerId,
        providerId: booking.providerId,
        amount: dto.amount,
        platformFee,
        providerAmount,
        paymentMethod: dto.paymentMethod,
        status: 'pending',
      },
    });

    console.log('[Payment] Created booking payment:', {
      id: bookingPayment.id.toString(),
      amount: dto.amount,
      platformFee,
      providerAmount,
      method: dto.paymentMethod,
    });

    // If MoMo, create payment request
    if (dto.paymentMethod === 'MOMO') {
      const orderId = `LSP_${bookingPayment.id}_${Date.now()}`;
      const momoResponse = await this.momoService.createPayment({
        orderId,
        amount: dto.amount,
        orderInfo: `Thanh toán dịch vụ #${booking.code || booking.id}`,
        extraData: Buffer.from(
          JSON.stringify({
            bookingPaymentId: bookingPayment.id.toString(),
            bookingId: dto.bookingId.toString(),
          }),
        ).toString('base64'),
      });

      return {
        bookingPayment: this.formatBookingPayment(bookingPayment),
        momo: {
          payUrl: momoResponse.payUrl,
          qrCodeUrl: momoResponse.qrCodeUrl,
          deeplink: momoResponse.deeplink,
        },
      };
    }

    // COD - just return payment info
    return {
      bookingPayment: this.formatBookingPayment(bookingPayment),
      message: 'Thanh toán tiền mặt khi hoàn thành dịch vụ',
    };
  }

  /**
   * Handle MoMo IPN callback
   */
  async handleMomoCallback(data: MomoCallbackData) {
    console.log('[Payment] MoMo callback received:', data);

    // Verify signature
    if (!this.momoService.verifySignature(data)) {
      console.error('[Payment] Invalid MoMo signature');
      throw new BadRequestException('Invalid signature');
    }

    // Parse extraData
    let extraData: any = {};
    try {
      extraData = JSON.parse(Buffer.from(data.extraData, 'base64').toString());
    } catch (e) {
      console.error('[Payment] Failed to parse extraData:', e);
    }

    const bookingPaymentId = extraData.bookingPaymentId
      ? BigInt(extraData.bookingPaymentId)
      : null;

    if (!bookingPaymentId) {
      console.error('[Payment] No bookingPaymentId in extraData');
      return { success: false, message: 'Missing bookingPaymentId' };
    }

    const bookingPayment = await this.prisma.bookingPayment.findUnique({
      where: { id: bookingPaymentId },
    });

    if (!bookingPayment) {
      console.error(
        '[Payment] BookingPayment not found:',
        bookingPaymentId.toString(),
      );
      return { success: false, message: 'Payment not found' };
    }

    // Check result
    if (this.momoService.isPaymentSuccessful(data.resultCode)) {
      // Payment successful - move to HELD (escrow)
      await this.prisma.bookingPayment.update({
        where: { id: bookingPaymentId },
        data: {
          status: 'held',
          momoTransId: data.transId.toString(),
          paidAt: new Date(),
          heldAt: new Date(),
        },
      });

      console.log(
        '[Payment] Payment held in escrow:',
        bookingPaymentId.toString(),
      );
      return { success: true, message: 'Payment held in escrow' };
    } else {
      // Payment failed
      console.log('[Payment] Payment failed:', data.message);
      return { success: false, message: data.message };
    }
  }

  /**
   * Confirm COD payment (provider collected cash)
   */
  async confirmCodPayment(bookingPaymentId: bigint, providerId: bigint) {
    const payment = await this.prisma.bookingPayment.findUnique({
      where: { id: bookingPaymentId },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    if (payment.providerId !== providerId) {
      throw new BadRequestException('Not authorized');
    }

    if (payment.paymentMethod !== 'COD') {
      throw new BadRequestException('Not a COD payment');
    }

    if (payment.status !== 'pending') {
      throw new BadRequestException('Payment already processed');
    }

    // For COD, move directly to HELD status
    const updated = await this.prisma.bookingPayment.update({
      where: { id: bookingPaymentId },
      data: {
        status: 'held',
        paidAt: new Date(),
        heldAt: new Date(),
      },
    });

    console.log(
      '[Payment] COD payment confirmed:',
      bookingPaymentId.toString(),
    );
    return this.formatBookingPayment(updated);
  }

  /**
   * Release payment to provider (after service completed)
   */
  async releasePayment(bookingPaymentId: bigint) {
    const payment = await this.prisma.bookingPayment.findUnique({
      where: { id: bookingPaymentId },
      include: { provider: { include: { wallet: true } } },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    if (payment.status !== 'held') {
      throw new BadRequestException(
        `Cannot release payment in ${payment.status} status`,
      );
    }

    // Update payment status
    const updated = await this.prisma.bookingPayment.update({
      where: { id: bookingPaymentId },
      data: {
        status: 'released',
        releasedAt: new Date(),
      },
    });

    // Add provider earnings to wallet
    await this.prisma.wallet.upsert({
      where: { userId: payment.providerId },
      create: {
        userId: payment.providerId,
        balance: payment.providerAmount,
      },
      update: {
        balance: { increment: payment.providerAmount },
      },
    });

    // Create wallet transaction
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId: payment.providerId },
    });

    await this.prisma.walletTransaction.create({
      data: {
        walletUserId: payment.providerId,
        type: 'earning',
        amount: payment.providerAmount,
        balanceAfter: wallet?.balance || payment.providerAmount,
        status: 'completed',
        metadata: {
          bookingPaymentId: bookingPaymentId.toString(),
          bookingId: payment.bookingId.toString(),
        },
      },
    });

    console.log('[Payment] Payment released:', {
      paymentId: bookingPaymentId.toString(),
      providerAmount: payment.providerAmount.toString(),
    });

    return this.formatBookingPayment(updated);
  }

  /**
   * Refund payment to customer
   */
  async refundPayment(bookingPaymentId: bigint, reason: string) {
    const payment = await this.prisma.bookingPayment.findUnique({
      where: { id: bookingPaymentId },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    if (payment.status !== 'held' && payment.status !== 'pending') {
      throw new BadRequestException(
        `Cannot refund payment in ${payment.status} status`,
      );
    }

    // Update payment status
    const updated = await this.prisma.bookingPayment.update({
      where: { id: bookingPaymentId },
      data: {
        status: 'refunded',
        refundedAt: new Date(),
      },
    });

    // TODO: If MoMo payment, initiate refund via MoMo API
    // For now, manual refund is required

    console.log('[Payment] Payment refunded:', {
      paymentId: bookingPaymentId.toString(),
      reason,
    });

    return this.formatBookingPayment(updated);
  }

  /**
   * Get booking payment by ID
   */
  async getBookingPayment(id: bigint) {
    const payment = await this.prisma.bookingPayment.findUnique({
      where: { id },
      include: {
        booking: true,
        customer: { include: { profile: true } },
        provider: { include: { profile: true } },
      },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    return this.formatBookingPayment(payment);
  }

  /**
   * Get payments by provider
   */
  async getProviderPayments(providerId: bigint, status?: string) {
    const where: any = { providerId };
    if (status) {
      where.status = status;
    }

    const payments = await this.prisma.bookingPayment.findMany({
      where,
      include: {
        booking: true,
        customer: { include: { profile: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return payments.map((p) => this.formatBookingPayment(p));
  }

  /**
   * Format booking payment for response
   */
  private formatBookingPayment(payment: any) {
    return {
      id: payment.id.toString(),
      bookingId: payment.bookingId.toString(),
      customerId: payment.customerId.toString(),
      providerId: payment.providerId.toString(),
      amount: Number(payment.amount),
      platformFee: Number(payment.platformFee),
      providerAmount: Number(payment.providerAmount),
      paymentMethod: payment.paymentMethod,
      momoTransId: payment.momoTransId,
      status: payment.status,
      paidAt: payment.paidAt,
      heldAt: payment.heldAt,
      releasedAt: payment.releasedAt,
      refundedAt: payment.refundedAt,
      createdAt: payment.createdAt,
      booking: payment.booking
        ? {
            id: payment.booking.id.toString(),
            code: payment.booking.code,
            status: payment.booking.status,
          }
        : undefined,
      customer: payment.customer?.profile
        ? {
            id: payment.customer.id.toString(),
            fullName: payment.customer.profile.fullName,
            phone: payment.customer.phone,
          }
        : undefined,
      provider: payment.provider?.profile
        ? {
            id: payment.provider.id.toString(),
            fullName: payment.provider.profile.fullName,
          }
        : undefined,
    };
  }
}
