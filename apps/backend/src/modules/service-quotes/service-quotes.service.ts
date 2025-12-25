import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateServiceQuoteDto,
  AcceptQuoteDto,
  RejectQuoteDto,
} from './dto/service-quote.dto';
import { QuoteStatus, BookingStatus } from '@prisma/client';

import { ChatGateway } from '../conversations/chat.gateway';

@Injectable()
export class ServiceQuotesService {
  constructor(
    private prisma: PrismaService,
    private chatGateway: ChatGateway,
  ) {}

  // Platform fee percentage
  private readonly PLATFORM_FEE_RATE = 0.1; // 10%

  /**
   * Provider creates a quote for a booking after inspection
   */
  async createQuote(
    bookingId: bigint,
    providerId: bigint,
    dto: CreateServiceQuoteDto,
  ) {
    // Verify booking exists and belongs to this provider
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        customer: {
          include: { profile: true },
        },
        service: true,
      },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('You are not the provider for this booking');
    }

    // Only allow quotes for accepted or in_progress bookings
    if (!['accepted', 'in_progress'].includes(booking.status)) {
      throw new BadRequestException(
        `Cannot create quote for booking with status: ${booking.status}`,
      );
    }

    // Calculate costs
    const partsCost = dto.items.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0,
    );
    const totalCost = partsCost + dto.laborCost;
    const platformFee = Math.round(totalCost * this.PLATFORM_FEE_RATE);
    const finalPrice = totalCost + platformFee;

    // Create quote with 24h expiry
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    const quote = await this.prisma.serviceQuote.create({
      data: {
        bookingId,
        providerId,
        diagnosis: dto.diagnosis,
        items: dto.items as any, // Cast to Prisma JSON type
        laborCost: dto.laborCost,
        partsCost,
        totalCost,
        platformFee,
        finalPrice,
        warranty: dto.warranty,
        estimatedTime: dto.estimatedTime,
        images: dto.images || [],
        notes: dto.notes,
        status: QuoteStatus.pending,
        expiresAt,
      },
      include: {
        provider: {
          select: {
            id: true,
            phone: true,
            profile: { select: { fullName: true, avatarUrl: true } },
          },
        },
      },
    });

    // Send notification to customer about new quote
    this.chatGateway.notifyUser(
      booking.customerId.toString(),
      'booking.quote_received',
      {
        bookingId: booking.id.toString(),
        quoteId: quote.id.toString(),
        serviceName: booking.service?.name,
        finalPrice: finalPrice,
        providerName: quote.provider?.profile?.fullName,
      },
    );

    return {
      ...this.serializeQuote(quote),
      message: 'Báo giá đã được gửi cho khách hàng',
    };
  }

  /**
   * Get quotes for a booking
   */
  async getQuotesForBooking(bookingId: bigint, userId: bigint) {
    // Verify user has access to this booking
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.customerId !== userId && booking.providerId !== userId) {
      throw new ForbiddenException('You do not have access to this booking');
    }

    const quotes = await this.prisma.serviceQuote.findMany({
      where: { bookingId },
      include: {
        provider: {
          select: {
            id: true,
            phone: true,
            profile: { select: { fullName: true, avatarUrl: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return quotes.map(this.serializeQuote);
  }

  /**
   * Customer accepts a quote
   */
  async acceptQuote(quoteId: bigint, customerId: bigint, dto?: AcceptQuoteDto) {
    const quote = await this.prisma.serviceQuote.findUnique({
      where: { id: quoteId },
      include: { booking: true },
    });

    if (!quote) {
      throw new NotFoundException('Quote not found');
    }

    if (quote.booking.customerId !== customerId) {
      throw new ForbiddenException('Only the customer can accept this quote');
    }

    if (quote.status !== QuoteStatus.pending) {
      throw new BadRequestException(`Quote is already ${quote.status}`);
    }

    if (new Date() > quote.expiresAt) {
      throw new BadRequestException('Quote has expired');
    }

    // Update quote status and booking
    const [updatedQuote] = await this.prisma.$transaction([
      this.prisma.serviceQuote.update({
        where: { id: quoteId },
        data: {
          status: QuoteStatus.accepted,
          acceptedAt: new Date(),
        },
      }),
      this.prisma.booking.update({
        where: { id: quote.bookingId },
        data: {
          status: BookingStatus.in_progress,
          estimatedPrice: quote.finalPrice,
          additionalNotes: dto?.customerNote
            ? `Khách hàng: ${dto.customerNote}`
            : undefined,
        },
      }),
      // Reject other pending quotes for this booking
      this.prisma.serviceQuote.updateMany({
        where: {
          bookingId: quote.bookingId,
          id: { not: quoteId },
          status: QuoteStatus.pending,
        },
        data: { status: QuoteStatus.rejected },
      }),
    ]);

    // TODO: Send notification to provider

    return {
      ...this.serializeQuote(updatedQuote),
      message: 'Đã chấp nhận báo giá. Thợ sẽ tiến hành thực hiện dịch vụ.',
    };
  }

  /**
   * Customer rejects a quote
   */
  async rejectQuote(quoteId: bigint, customerId: bigint, dto: RejectQuoteDto) {
    const quote = await this.prisma.serviceQuote.findUnique({
      where: { id: quoteId },
      include: { booking: true },
    });

    if (!quote) {
      throw new NotFoundException('Quote not found');
    }

    if (quote.booking.customerId !== customerId) {
      throw new ForbiddenException('Only the customer can reject this quote');
    }

    if (quote.status !== QuoteStatus.pending) {
      throw new BadRequestException(`Quote is already ${quote.status}`);
    }

    const updatedQuote = await this.prisma.serviceQuote.update({
      where: { id: quoteId },
      data: {
        status: QuoteStatus.rejected,
        notes: quote.notes
          ? `${quote.notes}\n---\nLý do từ chối: ${dto.reason}`
          : `Lý do từ chối: ${dto.reason}`,
      },
    });

    // TODO: Send notification to provider

    return {
      ...this.serializeQuote(updatedQuote),
      message: 'Đã từ chối báo giá.',
    };
  }

  /**
   * Get quote by ID
   */
  async getQuoteById(quoteId: bigint, userId: bigint) {
    const quote = await this.prisma.serviceQuote.findUnique({
      where: { id: quoteId },
      include: {
        booking: {
          include: {
            customer: {
              select: {
                id: true,
                phone: true,
                profile: { select: { fullName: true } },
              },
            },
            service: { select: { id: true, name: true } },
          },
        },
        provider: {
          select: {
            id: true,
            phone: true,
            profile: { select: { fullName: true, avatarUrl: true } },
          },
        },
      },
    });

    if (!quote) {
      throw new NotFoundException('Quote not found');
    }

    // Check access
    if (quote.booking.customerId !== userId && quote.providerId !== userId) {
      throw new ForbiddenException('You do not have access to this quote');
    }

    return this.serializeQuote(quote);
  }

  /**
   * Serialize quote for API response
   */
  private serializeQuote(quote: any) {
    return {
      id: quote.id.toString(),
      bookingId: quote.bookingId.toString(),
      providerId: quote.providerId.toString(),
      diagnosis: quote.diagnosis,
      items: quote.items,
      laborCost: Number(quote.laborCost),
      partsCost: Number(quote.partsCost),
      totalCost: Number(quote.totalCost),
      platformFee: Number(quote.platformFee),
      finalPrice: Number(quote.finalPrice),
      warranty: quote.warranty,
      estimatedTime: quote.estimatedTime,
      images: quote.images,
      notes: quote.notes,
      status: quote.status,
      createdAt: quote.createdAt,
      expiresAt: quote.expiresAt,
      acceptedAt: quote.acceptedAt,
      provider: quote.provider
        ? {
            id: quote.provider.id.toString(),
            phone: quote.provider.phone,
            fullName: quote.provider.profile?.fullName,
            avatarUrl: quote.provider.profile?.avatarUrl,
          }
        : undefined,
      booking: quote.booking
        ? {
            id: quote.booking.id.toString(),
            customerName: quote.booking.customer?.profile?.fullName,
            serviceName: quote.booking.service?.name,
          }
        : undefined,
    };
  }
}
