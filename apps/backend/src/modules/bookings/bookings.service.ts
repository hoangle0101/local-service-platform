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

      // 1. Create Booking (Pending, no provider yet)
      const code = `BK${Date.now()}`;
      const basePrice = Number(service.basePrice); // Initial estimate

      const bookingIdResult = await tx.$queryRawUnsafe<any[]>(
        `
        INSERT INTO bookings (
          code, customer_id, service_id,
          status, scheduled_at, address_text, location, notes,
          estimated_price, created_at, updated_at
        ) VALUES (
          $1, $2, $3,
          'pending', $4, $5, ST_SetSRID(ST_MakePoint($6, $7), 4326), $8,
          $9, NOW(), NOW()
        ) RETURNING id, code, status, scheduled_at, estimated_price
      `,
        code,
        customerId,
        dto.serviceId,
        new Date(dto.scheduledAt),
        dto.addressText,
        dto.longitude,
        dto.latitude,
        dto.notes || null,
        basePrice,
      );

      const booking = bookingIdResult[0];
      const bookingId = booking.id;

      // 2. Find Nearby Providers
      const providers = await this.findNearbyProviders(
        dto.serviceId,
        dto.latitude,
        dto.longitude,
        tx,
      );

      // 3. Notify Providers (via Socket)
      // We can't inject SocketGateway here directly if it causes circular dependency or if we are in transaction
      // Ideally, we return the list of provider IDs and emit events after transaction commits.
      // For now, we'll assume we can emit after this function returns in the controller.

      return {
        id: booking.id.toString(),
        code: booking.code,
        status: booking.status,
        scheduledAt: booking.scheduled_at,
        estimatedPrice: booking.estimated_price?.toString(),
        nearbyProviderIds: providers.map((p) => (p as any).user_id.toString()),
      };
    });
  }

  // Helper: Find nearby providers (multiple)
  private async findNearbyProviders(
    serviceId: number,
    latitude: number,
    longitude: number,
    tx?: any,
  ) {
    const prisma = tx || this.prisma;
    const radiusMeters = 10000; // 10km radius

    return await prisma.$queryRawUnsafe(
      `
      SELECT 
        pp.user_id,
        pp.display_name,
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
          $4
        )
      ORDER BY distance ASC
      LIMIT 10
    `,
      longitude,
      latitude,
      serviceId,
      radiusMeters,
    );
  }

  async acceptBookingRequest(providerId: bigint, bookingId: bigint) {
    // Check if booking exists and is pending
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.status !== 'pending')
      throw new BadRequestException('Booking is not pending');

    // Check if provider offers this service
    const providerService = await this.prisma.providerService.findUnique({
      where: {
        providerUserId_serviceId: {
          providerUserId: providerId,
          serviceId: booking.serviceId,
        },
      },
    });

    if (!providerService)
      throw new ForbiddenException('You do not provide this service');

    // Create BookingOffer using raw SQL (until Prisma regenerates)
    const offerResult = await this.prisma.$queryRawUnsafe<any[]>(
      `
      INSERT INTO booking_offers (booking_id, provider_id, price, status, created_at, updated_at)
      VALUES ($1, $2, $3, 'PENDING', NOW(), NOW())
      RETURNING id
    `,
      bookingId,
      providerId,
      Number(providerService.price),
    );

    return {
      message: 'Offer sent',
      offerId: offerResult[0].id.toString(),
      bookingId: bookingId.toString(),
      customerId: booking.customerId.toString(),
    };
  }

  async selectProvider(
    customerId: bigint,
    bookingId: bigint,
    providerId: bigint,
  ) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.customerId !== customerId)
      throw new ForbiddenException('Not your booking');

    // Verify offer exists using raw SQL
    const offers = await this.prisma.$queryRawUnsafe<any[]>(
      `
      SELECT id, price FROM booking_offers 
      WHERE booking_id = $1 AND provider_id = $2
    `,
      bookingId,
      providerId,
    );

    if (!offers || offers.length === 0)
      throw new NotFoundException('Provider offer not found');

    const offer = offers[0];

    // Update Booking and Offers
    return await this.prisma.$transaction(async (tx) => {
      // Update Booking
      const updatedBooking = await tx.booking.update({
        where: { id: bookingId },
        data: {
          providerId,
          providerServicePrice: offer.price,
          status: 'accepted',
          estimatedPrice: offer.price,
        },
      });

      // Update Offers using raw SQL
      await tx.$executeRawUnsafe(
        `
        UPDATE booking_offers SET status = 'ACCEPTED', updated_at = NOW() WHERE id = $1
      `,
        offer.id,
      );

      await tx.$executeRawUnsafe(
        `
        UPDATE booking_offers SET status = 'REJECTED', updated_at = NOW() 
        WHERE booking_id = $1 AND id != $2
      `,
        bookingId,
        offer.id,
      );

      return {
        message: 'Provider selected',
        bookingId: updatedBooking.id.toString(),
        providerId: providerId.toString(),
      };
    });
  }

  // GET /bookings/:id/offers
  async getBookingOffers(userId: bigint, bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.customerId !== userId)
      throw new ForbiddenException('Not your booking');

    // Get offers using raw SQL
    const offers = await this.prisma.$queryRawUnsafe<any[]>(
      `
      SELECT 
        bo.id,
        bo.booking_id,
        bo.provider_id,
        bo.price,
        bo.status,
        pp.display_name as provider_name,
        pp.rating_avg
      FROM booking_offers bo
      JOIN provider_profiles pp ON bo.provider_id = pp.user_id
      WHERE bo.booking_id = $1
      ORDER BY bo.created_at DESC
    `,
      bookingId,
    );

    return {
      offers: offers.map((o) => ({
        id: o.id.toString(),
        bookingId: o.booking_id.toString(),
        providerId: o.provider_id.toString(),
        providerName: o.provider_name,
        rating: o.rating_avg?.toString(),
        price: o.price.toString(),
        status: o.status,
      })),
    };
  }

  // GET /provider/bookings/requests
  async getProviderRequests(providerId: bigint) {
    // Find pending bookings where the provider offers the service
    // and hasn't already made an offer
    const requests = await this.prisma.$queryRawUnsafe<any[]>(
      `
      SELECT DISTINCT
        b.id,
        b.code,
        b.status,
        b.scheduled_at,
        b.address_text,
        b.estimated_price,
        s.name as service_name,
        up.full_name as customer_name,
        ST_Distance(
          b.location::geography,
          pp.location::geography
        ) as distance
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      JOIN user_profiles up ON b.customer_id = up.user_id
      JOIN provider_services ps ON ps.service_id = b.service_id AND ps.provider_user_id = $1
      JOIN provider_profiles pp ON pp.user_id = $1
      LEFT JOIN booking_offers bo ON bo.booking_id = b.id AND bo.provider_id = $1
      WHERE b.status = 'pending'
        AND b.provider_id IS NULL
        AND bo.id IS NULL
        AND ps.is_active = true
        AND ST_DWithin(
          b.location::geography,
          pp.location::geography,
          pp.service_radius_m
        )
      ORDER BY b.created_at DESC
      LIMIT 20
    `,
      providerId,
    );

    return {
      requests: requests.map((r) => ({
        id: r.id.toString(),
        code: r.code,
        status: r.status,
        scheduledAt: r.scheduled_at,
        addressText: r.address_text,
        estimatedPrice: r.estimated_price?.toString(),
        serviceName: r.service_name,
        customerName: r.customer_name,
        distance: Math.round(r.distance),
      })),
    };
  }

  // GET /bookings
  async getBookings(userId: bigint, query: BookingQueryDto) {
    const where: any = {
      OR: [{ customerId: userId }, { providerId: userId }],
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
  async cancelBooking(
    userId: bigint,
    bookingId: bigint,
    dto: CancelBookingDto,
  ) {
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
  async reviewBooking(
    userId: bigint,
    bookingId: bigint,
    dto: ReviewBookingDto,
  ) {
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
    const providers = await prisma.$queryRawUnsafe(
      `
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
    `,
      longitude,
      latitude,
      serviceId,
    );

    return Array.isArray(providers) && providers.length > 0
      ? providers[0]
      : null;
  }
}
