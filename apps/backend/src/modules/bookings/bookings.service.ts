import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  EstimateDto,
  CreateBookingDto,
  CancelBookingDto,
  ReviewBookingDto,
  BookingQueryDto,
} from './dto/bookings.dto';

@Injectable()
export class BookingsService {
  constructor(private prisma: PrismaService) {}

  // POST /bookings/estimate
  async estimateBooking(dto: EstimateDto) {
    const service = await this.prisma.service.findUnique({
      where: { id: dto.serviceId },
    });

    if (!service) {
      throw new NotFoundException('Service not found');
    }

    // Find nearest provider
    let provider = null;
    if (dto.latitude && dto.longitude) {
      provider = await this.findNearestProvider(
        dto.serviceId,
        dto.latitude,
        dto.longitude,
      );
    }

    const basePrice = Number(service.basePrice);
    const platformFee = basePrice * 0.1; // 10% platform fee
    const totalAmount = basePrice + platformFee;

    return {
      serviceId: dto.serviceId,
      serviceName: service.name,
      basePrice: basePrice.toString(),
      platformFee: platformFee.toString(),
      totalAmount: totalAmount.toString(),
      estimatedDuration: service.durationMinutes,
      provider: provider
        ? {
            id: (provider as any).user_id.toString(),
            displayName: (provider as any).display_name,
            ratingAvg: (provider as any).rating_avg?.toString() || '0',
          }
        : null,
    };
  }

  // POST /bookings
  async createBooking(customerId: bigint, dto: CreateBookingDto) {
    return await this.prisma.$transaction(async (tx) => {
      // Get service
      const service = await tx.service.findUnique({
        where: { id: dto.serviceId },
      });

      if (!service) {
        throw new NotFoundException('Service not found');
      }

      // Find provider
      const provider = await this.findNearestProvider(
        dto.serviceId,
        dto.latitude,
        dto.longitude,
        tx,
      );

      if (!provider) {
        throw new NotFoundException('No provider available for this service');
      }

      // Get provider service price
      const providerService = await tx.providerService.findUnique({
        where: {
          providerUserId_serviceId: {
            providerUserId: (provider as any).user_id,
            serviceId: dto.serviceId,
          },
        },
      });

      if (!providerService) {
        throw new NotFoundException('Provider service not found');
      }

      const basePrice = Number(providerService.price);
      const platformFee = basePrice * 0.1;
      const providerEarning = basePrice * 0.9;

      // Create booking
      // Use raw query for Point creation to ensure PostGIS compatibility
      const pointQuery = `ST_SetSRID(ST_MakePoint(${dto.longitude}, ${dto.latitude}), 4326)`;
      
      const code = `BK${Date.now()}`;
      
      // Insert Booking via raw SQL to handle PostGIS point
      const bookingIdResult = await tx.$queryRawUnsafe<any[]>(`
        INSERT INTO bookings (
          code, customer_id, provider_id, service_id, provider_service_price,
          status, scheduled_at, address_text, location, notes,
          estimated_price, platform_fee, provider_earning, created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4, $5,
          'pending', $6, $7, ST_SetSRID(ST_MakePoint($8, $9), 4326), $10,
          $11, $12, $13, NOW(), NOW()
        ) RETURNING id, code, status, scheduled_at, estimated_price
      `, 
        code, 
        customerId, 
        (provider as any).user_id, 
        dto.serviceId, 
        basePrice,
        new Date(dto.scheduledAt), 
        dto.addressText, 
        dto.longitude, 
        dto.latitude, 
        dto.notes || null,
        basePrice,
        platformFee,
        providerEarning
      );

      const booking = bookingIdResult[0];

      // Create booking event
      await tx.bookingEvent.create({
        data: {
          bookingId: booking.id,
          newStatus: 'pending',
          actorUserId: customerId,
          note: 'Booking created',
        },
      });

      return {
        id: booking.id.toString(),
        code: booking.code,
        status: booking.status,
        scheduledAt: booking.scheduled_at,
        estimatedPrice: booking.estimated_price?.toString(),
      };
    });
  }

  // GET /bookings
  async getBookings(userId: bigint, query: BookingQueryDto) {
    const where: any = {
      OR: [
        { customerId: userId },
        { providerId: userId },
      ],
    };

    if (query.status) {
      where.status = query.status;
    }

    const page = query.page || 1;
    const limit = query.limit || 20;

    const [bookings, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: {
          service: true,
          customer: {
            select: {
              id: true,
              profile: {
                select: { fullName: true, avatarUrl: true },
              },
            },
          },
          providerUser: {
            select: {
              id: true,
              profile: {
                select: { fullName: true, avatarUrl: true },
              },
            },
          },
        },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.booking.count({ where }),
    ]);

    return {
      bookings: bookings.map((b: any) => ({
        id: b.id.toString(),
        code: b.code,
        status: b.status,
        scheduledAt: b.scheduledAt,
        addressText: b.addressText,
        estimatedPrice: b.estimatedPrice?.toString(),
        actualPrice: b.actualPrice?.toString(),
        service: {
          id: b.service.id,
          name: b.service.name,
        },
        customer: {
          id: b.customer.id.toString(),
          fullName: b.customer.profile?.fullName,
          avatarUrl: b.customer.profile?.avatarUrl,
        },
        provider: b.providerUser
          ? {
              id: b.providerUser.id.toString(),
              fullName: b.providerUser.profile?.fullName,
              avatarUrl: b.providerUser.profile?.avatarUrl,
            }
          : null,
      })),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // GET /bookings/:id
  async getBookingById(userId: bigint, bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        service: true,
        customer: {
          select: {
            id: true,
            phone: true,
            profile: {
              select: { fullName: true, avatarUrl: true },
            },
          },
        },
        providerUser: {
          select: {
            id: true,
            phone: true,
            profile: {
              select: { fullName: true, avatarUrl: true },
            },
          },
        },
        bookingEvents: {
          orderBy: { createdAt: 'desc' },
        },
        review: true,
      },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    // Check access
    if (booking.customerId !== userId && booking.providerId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    // Cast to any to handle relations
    const b = booking as any;

    return {
      id: b.id.toString(),
      code: b.code,
      status: b.status,
      scheduledAt: b.scheduledAt,
      addressText: b.addressText,
      notes: b.notes,
      estimatedPrice: b.estimatedPrice?.toString(),
      actualPrice: b.actualPrice?.toString(),
      platformFee: b.platformFee.toString(),
      providerEarning: b.providerEarning.toString(),
      createdAt: b.createdAt,
      completedAt: b.completedAt,
      cancelledAt: b.cancelledAt,
      service: {
        id: b.service.id,
        name: b.service.name,
        description: b.service.description,
      },
      customer: {
        id: b.customer.id.toString(),
        phone: b.customer.phone,
        fullName: b.customer.profile?.fullName,
        avatarUrl: b.customer.profile?.avatarUrl,
      },
      provider: b.providerUser
        ? {
            id: b.providerUser.id.toString(),
            phone: b.providerUser.phone,
            fullName: b.providerUser.profile?.fullName,
            avatarUrl: b.providerUser.profile?.avatarUrl,
          }
        : null,
      timeline: b.bookingEvents.map((e: any) => ({
        status: e.newStatus,
        note: e.note,
        createdAt: e.createdAt,
        actor: e.actorUserId ? `User #${e.actorUserId}` : 'System',
      })),
      review: b.review
        ? {
            rating: b.review.rating,
            comment: b.review.comment,
            createdAt: b.review.createdAt,
          }
        : null,
    };
  }

  // PATCH /bookings/:id/cancel
  async cancelBooking(userId: bigint, bookingId: bigint, dto: CancelBookingDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.customerId !== userId) {
      throw new ForbiddenException('Not your booking');
    }

    if (!['pending', 'accepted'].includes(booking.status)) {
      throw new BadRequestException('Cannot cancel booking in current status');
    }

    return await this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: 'cancelled',
          cancelledAt: new Date(),
        },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: booking.status,
          newStatus: 'cancelled',
          actorUserId: userId,
          note: dto.reason,
        },
      });

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Booking cancelled successfully',
      };
    });
  }

  // PATCH /provider/bookings/:id/accept
  async acceptBooking(providerId: bigint, bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('Not your booking');
    }

    if (booking.status !== 'pending') {
      throw new BadRequestException('Booking is not pending');
    }

    return await this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: { status: 'accepted' },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'pending',
          newStatus: 'accepted',
          actorUserId: providerId,
          note: 'Provider accepted booking',
        },
      });

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Booking accepted',
      };
    });
  }

  // PATCH /provider/bookings/:id/start
  async startBooking(providerId: bigint, bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('Not your booking');
    }

    if (booking.status !== 'accepted') {
      throw new BadRequestException('Booking must be accepted first');
    }

    return await this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: { status: 'in_progress' },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'accepted',
          newStatus: 'in_progress',
          actorUserId: providerId,
          note: 'Provider started service',
        },
      });

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Service started',
      };
    });
  }

  // PATCH /provider/bookings/:id/complete
  async completeBooking(providerId: bigint, bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.providerId !== providerId) {
      throw new ForbiddenException('Not your booking');
    }

    if (booking.status !== 'in_progress') {
      throw new BadRequestException('Booking must be in progress');
    }

    return await this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: 'completed',
          completedAt: new Date(),
          actualPrice: booking.estimatedPrice, // Assuming no extra charges for now
        },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'in_progress',
          newStatus: 'completed',
          actorUserId: providerId,
          note: 'Provider completed service',
        },
      });

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Booking completed',
      };
    });
  }

  // POST /bookings/:id/review
  async reviewBooking(userId: bigint, bookingId: bigint, dto: ReviewBookingDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { review: true },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.customerId !== userId) {
      throw new ForbiddenException('Not your booking');
    }

    if (booking.status !== 'completed') {
      throw new BadRequestException('Can only review completed bookings');
    }

    if (booking.review) {
      throw new BadRequestException('Booking already reviewed');
    }

    return await this.prisma.$transaction(async (tx) => {
      // Create review
      const review = await tx.review.create({
        data: {
          bookingId,
          reviewerId: userId,
          revieweeId: booking.providerId!,
          rating: dto.rating,
          comment: dto.comment,
        },
      });

      // Update provider rating
      const providerStats = await tx.review.aggregate({
        where: { revieweeId: booking.providerId! },
        _avg: { rating: true },
        _count: { rating: true },
      });

      await tx.providerProfile.update({
        where: { userId: booking.providerId! },
        data: {
          ratingAvg: providerStats._avg.rating || 0,
          ratingCount: providerStats._count.rating || 0,
        },
      });

      return {
        id: review.id.toString(),
        rating: review.rating,
        comment: review.comment,
        message: 'Review submitted successfully',
      };
    });
  }

  // Helper: Find nearest provider
  private async findNearestProvider(
    serviceId: number,
    latitude: number,
    longitude: number,
    tx?: any,
  ) {
    const prisma = tx || this.prisma;

    // Use queryRawUnsafe for dynamic params
    // Cast geography to text to avoid Prisma deserialization error
    const providers = await prisma.$queryRawUnsafe(`
      SELECT 
        pp.user_id,
        pp.display_name,
        pp.bio,
        pp.rating_avg,
        pp.rating_count,
        pp.is_available,
        pp.service_radius_m,
        ST_AsText(pp.location) as location_text,
        ST_Distance(
          pp.location::geography,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
        ) as distance
      FROM provider_profiles pp
      INNER JOIN provider_services ps ON pp.user_id = ps.provider_user_id
      WHERE ps.service_id = $3
        AND ps.is_active = true
        AND ps.deleted_at IS NULL
        AND pp.is_available = true
        AND ST_DWithin(
          pp.location::geography,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
          pp.service_radius_m
        )
      ORDER BY distance ASC
      LIMIT 1
    `, longitude, latitude, serviceId);

    return Array.isArray(providers) && providers.length > 0 ? providers[0] : null;
  }
}
