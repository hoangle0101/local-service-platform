import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { MomoService } from './momo.service';

const PLATFORM_FEE_RATE = 0.1; // 10%

@Injectable()
export class BookingPaymentService {
  constructor(
    private prisma: PrismaService,
    private momoService: MomoService,
  ) {}

  /**
   * Provider updates final price (after service completion)
   */
  async updateFinalPrice(
    bookingId: bigint,
    providerId: bigint,
    data: {
      actualPrice: number;
      additionalCosts?: number;
      additionalNotes?: string;
    },
  ) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking không tồn tại');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('Bạn không có quyền cập nhật booking này');
    }

    if (!['confirmed', 'in_progress'].includes(booking.status)) {
      throw new BadRequestException('Không thể cập nhật giá ở trạng thái này');
    }

    const totalPrice = data.actualPrice + (data.additionalCosts || 0);
    const platformFee = Math.round(totalPrice * PLATFORM_FEE_RATE);
    const providerEarning = totalPrice - platformFee;

    const updated = await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        actualPrice: data.actualPrice,
        additionalCosts: data.additionalCosts || 0,
        additionalNotes: data.additionalNotes,
        platformFee,
        providerEarning,
      },
    });

    console.log('[BookingPayment] Price updated:', {
      bookingId: bookingId.toString(),
      actualPrice: data.actualPrice,
      additionalCosts: data.additionalCosts,
      platformFee,
      providerEarning,
    });

    return this.formatBookingPaymentInfo(updated);
  }

  /**
   * Provider marks service as complete → pending_payment
   */
  async markServiceComplete(bookingId: bigint, providerId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking không tồn tại');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('Bạn không có quyền cập nhật booking này');
    }

    if (!['confirmed', 'in_progress'].includes(booking.status)) {
      throw new BadRequestException('Không thể hoàn thành ở trạng thái này');
    }

    // If no actual price set, use estimated price
    const actualPrice =
      booking.actualPrice ||
      booking.estimatedPrice ||
      booking.providerServicePrice;
    if (!actualPrice) {
      throw new BadRequestException(
        'Vui lòng cập nhật giá trước khi hoàn thành',
      );
    }

    const totalPrice =
      Number(actualPrice) + Number(booking.additionalCosts || 0);
    const platformFee = Math.round(totalPrice * PLATFORM_FEE_RATE);
    const providerEarning = totalPrice - platformFee;

    const updated = await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: 'pending_payment' as any, // Will need to add to enum
        actualPrice: totalPrice,
        platformFee,
        providerEarning,
        completedAt: new Date(),
      },
    });

    // Create booking event
    await this.prisma.bookingEvent.create({
      data: {
        bookingId,
        previousStatus: booking.status,
        newStatus: 'pending_payment' as any,
        actorUserId: providerId,
        note: 'Dịch vụ hoàn thành, chờ thanh toán',
      },
    });

    console.log('[BookingPayment] Service marked complete:', {
      bookingId: bookingId.toString(),
      totalPrice,
      platformFee,
      providerEarning,
    });

    return this.formatBookingPaymentInfo(updated);
  }

  /**
   * Get invoice for pending_payment booking
   */
  async getInvoice(bookingId: bigint, userId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        service: true,
        providerUser: {
          include: { profile: true },
        },
        customer: {
          include: { profile: true },
        },
      },
    });

    if (!booking) {
      throw new NotFoundException('Booking không tồn tại');
    }

    if (booking.customerId !== userId && booking.providerId !== userId) {
      throw new ForbiddenException('Bạn không có quyền xem hóa đơn này');
    }

    const estimatedPrice = Number(
      booking.estimatedPrice || booking.providerServicePrice || 0,
    );
    const actualPrice = Number(booking.actualPrice || 0);
    const additionalCosts = Number(booking.additionalCosts || 0);
    const platformFee = Number(booking.platformFee || 0);
    const totalAmount = actualPrice > 0 ? actualPrice : estimatedPrice;

    return {
      bookingId: booking.id.toString(),
      bookingCode: booking.code,
      status: booking.status,
      paymentStatus: booking.paymentStatus,
      paymentMethod: booking.paymentMethod,
      service: {
        name: booking.service.name,
      },
      provider: {
        id: booking.providerUser?.id.toString(),
        name: booking.providerUser?.profile?.fullName,
      },
      customer: {
        id: booking.customer.id.toString(),
        name: booking.customer.profile?.fullName,
      },
      pricing: {
        estimatedPrice,
        actualPrice: actualPrice > 0 ? actualPrice : null,
        additionalCosts: additionalCosts > 0 ? additionalCosts : null,
        additionalNotes: booking.additionalNotes,
        platformFee,
        totalAmount:
          totalAmount +
          (additionalCosts > 0 && actualPrice === 0 ? additionalCosts : 0),
      },
      createdAt: booking.createdAt,
      completedAt: booking.completedAt,
    };
  }

  /**
   * Provider confirms COD payment received
   */
  async confirmCodPayment(bookingId: bigint, providerId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking không tồn tại');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('Bạn không có quyền xác nhận booking này');
    }

    if (booking.status !== 'pending_payment') {
      throw new BadRequestException(
        'Booking không ở trạng thái chờ thanh toán',
      );
    }

    if (booking.paymentMethod !== 'cod') {
      throw new BadRequestException('Booking không dùng phương thức COD');
    }

    // Complete the booking and payment
    const updated = await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: 'completed',
        paymentStatus: 'paid',
        paidAt: new Date(),
      },
    });

    // Add provider earnings to wallet
    await this.addProviderEarnings(
      providerId,
      Number(booking.providerEarning),
      bookingId,
    );

    // Create booking event
    await this.prisma.bookingEvent.create({
      data: {
        bookingId,
        previousStatus: 'pending_payment' as any,
        newStatus: 'completed',
        actorUserId: providerId,
        note: 'Đã nhận thanh toán tiền mặt',
      },
    });

    console.log('[BookingPayment] COD confirmed:', bookingId.toString());

    return this.formatBookingPaymentInfo(updated);
  }

  /**
   * Customer initiates MoMo payment for pending_payment booking
   */
  async initiateMomoPayment(bookingId: bigint, customerId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking không tồn tại');
    }

    if (booking.customerId !== customerId) {
      throw new ForbiddenException('Bạn không có quyền thanh toán booking này');
    }

    if (booking.status !== 'pending_payment') {
      throw new BadRequestException(
        'Booking không ở trạng thái chờ thanh toán',
      );
    }

    const totalAmount = Number(
      booking.actualPrice || booking.estimatedPrice || 0,
    );
    if (totalAmount <= 0) {
      throw new BadRequestException('Số tiền thanh toán không hợp lệ');
    }

    // Create MoMo payment
    const orderId = `BK${booking.id}_${Date.now()}`;
    const momoResponse = await this.momoService.createPayment({
      orderId,
      amount: Math.round(totalAmount),
      orderInfo: `Thanh toán dịch vụ #${booking.code}`,
      extraData: bookingId.toString(),
    });

    // Update payment status
    await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        paymentStatus: 'pending',
      },
    });

    return {
      bookingId: booking.id.toString(),
      amount: totalAmount,
      orderId,
      payUrl: momoResponse.payUrl,
      qrCodeUrl: momoResponse.qrCodeUrl,
      deeplink: momoResponse.deeplink,
    };
  }

  /**
   * Handle MoMo payment callback
   */
  async handleMomoCallback(data: any) {
    console.log('[BookingPayment] MoMo callback:', data);

    // Verify signature
    if (!this.momoService.verifySignature(data)) {
      console.error('[BookingPayment] Invalid MoMo signature');
      return;
    }

    // Extract booking ID from extraData
    const bookingId = BigInt(data.extraData);
    const isSuccess = this.momoService.isPaymentSuccessful(data.resultCode);

    if (isSuccess) {
      const booking = await this.prisma.booking.findUnique({
        where: { id: bookingId },
      });

      if (booking && booking.status === 'pending_payment') {
        // Complete payment
        await this.prisma.booking.update({
          where: { id: bookingId },
          data: {
            status: 'completed',
            paymentStatus: 'paid',
            paidAt: new Date(),
          },
        });

        // Add provider earnings
        if (booking.providerId) {
          await this.addProviderEarnings(
            booking.providerId,
            Number(booking.providerEarning),
            bookingId,
          );
        }

        console.log(
          '[BookingPayment] MoMo payment successful:',
          bookingId.toString(),
        );
      }
    } else {
      console.log('[BookingPayment] MoMo payment failed:', data.message);
    }
  }

  /**
   * Add earnings to provider wallet
   */
  private async addProviderEarnings(
    providerId: bigint,
    amount: number,
    bookingId: bigint,
  ) {
    // Find or create wallet
    let wallet = await this.prisma.wallet.findUnique({
      where: { userId: providerId },
    });

    if (!wallet) {
      wallet = await this.prisma.wallet.create({
        data: {
          userId: providerId,
          balance: 0,
        },
      });
    }

    // Update wallet balance
    const updatedWallet = await this.prisma.wallet.update({
      where: { userId: providerId },
      data: {
        balance: { increment: amount },
      },
    });

    // Create wallet transaction
    await this.prisma.walletTransaction.create({
      data: {
        walletUserId: providerId,
        type: 'earning',
        amount,
        balanceAfter: updatedWallet.balance,
        status: 'completed',
        metadata: {
          bookingId: bookingId.toString(),
          description: 'Thu nhập từ dịch vụ',
        },
      },
    });

    console.log('[BookingPayment] Earnings added:', {
      providerId: providerId.toString(),
      amount,
    });
  }

  /**
   * Format booking payment info for response
   */
  private formatBookingPaymentInfo(booking: any) {
    return {
      id: booking.id.toString(),
      code: booking.code,
      status: booking.status,
      paymentStatus: booking.paymentStatus,
      paymentMethod: booking.paymentMethod,
      estimatedPrice: Number(booking.estimatedPrice || 0),
      actualPrice: Number(booking.actualPrice || 0),
      additionalCosts: Number(booking.additionalCosts || 0),
      platformFee: Number(booking.platformFee || 0),
      providerEarning: Number(booking.providerEarning || 0),
      completedAt: booking.completedAt,
      paidAt: booking.paidAt,
    };
  }
}
