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
  constructor(private prisma: PrismaService) { }

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

      // 1. Create Booking
      // If providerId is specified, this is a Direct Booking (assigned to specific provider)
      // Otherwise, it's a General Booking (providers in that category will see it)
      const code = `BK${Date.now()}`;
      const basePrice = Number(service.basePrice); // Initial estimate
      const isDirectBooking = dto.providerId != null;

      // Debug logging
      console.log('[createBooking] DTO received:', {
        serviceId: dto.serviceId,
        providerId: dto.providerId,
        isDirectBooking,
        addressText: dto.addressText,
        latitude: dto.latitude,
        longitude: dto.longitude,
      });

      // VALIDATION 1: Prevent self-booking (provider cannot book their own service)
      if (isDirectBooking && BigInt(dto.providerId!) === customerId) {
        throw new BadRequestException(
          'Bạn không thể đặt dịch vụ của chính mình',
        );
      }

      // Also check if customer is the owner of the service they're trying to book
      const serviceProvider = await tx.providerService.findFirst({
        where: {
          serviceId: dto.serviceId,
          providerUserId: customerId,
          isActive: true,
        },
      });
      if (serviceProvider) {
        throw new BadRequestException(
          'Bạn không thể đặt dịch vụ của chính mình',
        );
      }

      // VALIDATION 2: Prevent duplicate booking
      // Rule 1: Cannot book same service with same provider again (any time)
      // Rule 2: Cannot book different service with same provider at same time (within 2 hours)
      const scheduledTime = new Date(dto.scheduledAt);
      const twoHoursBefore = new Date(
        scheduledTime.getTime() - 2 * 60 * 60 * 1000,
      );
      const twoHoursAfter = new Date(
        scheduledTime.getTime() + 2 * 60 * 60 * 1000,
      );

      // Rule 1: Check if same service + same provider already exists
      if (isDirectBooking) {
        const sameServiceBooking = await tx.booking.findFirst({
          where: {
            customerId: customerId,
            serviceId: dto.serviceId,
            providerId: BigInt(dto.providerId!),
            status: { in: ['pending', 'accepted', 'in_progress'] },
          },
        });

        if (sameServiceBooking) {
          throw new BadRequestException(
            'Bạn đã đặt dịch vụ này với provider này rồi. Vui lòng chọn dịch vụ khác hoặc provider khác.',
          );
        }

        // Rule 2: Check if different service but same provider + same time
        const sameTimeBooking = await tx.booking.findFirst({
          where: {
            customerId: customerId,
            providerId: BigInt(dto.providerId!),
            status: { in: ['pending', 'accepted', 'in_progress'] },
            scheduledAt: {
              gte: twoHoursBefore,
              lte: twoHoursAfter,
            },
          },
        });

        if (sameTimeBooking) {
          throw new BadRequestException(
            'Bạn đã có lịch đặt với provider này trong khoảng thời gian này. Vui lòng chọn thời gian khác.',
          );
        }
      } else {
        // General booking: just check same service + same time
        const existingBooking = await tx.booking.findFirst({
          where: {
            customerId: customerId,
            serviceId: dto.serviceId,
            status: { in: ['pending', 'accepted', 'in_progress'] },
            scheduledAt: {
              gte: twoHoursBefore,
              lte: twoHoursAfter,
            },
          },
        });

        if (existingBooking) {
          throw new BadRequestException(
            'Bạn đã có lịch đặt dịch vụ này trong khoảng thời gian tương tự. Vui lòng chọn thời gian khác.',
          );
        }
      }

      // Validate provider exists and is active if direct booking
      if (isDirectBooking) {
        console.log(
          '[createBooking] Direct booking - checking provider:',
          dto.providerId,
        );
        const providerExists = await tx.providerProfile.findUnique({
          where: { userId: BigInt(dto.providerId!) },
        });
        console.log('[createBooking] Provider exists:', !!providerExists);
        if (!providerExists) {
          throw new NotFoundException('Selected provider not found');
        }
      }

      const bookingIdResult = await tx.$queryRawUnsafe<any[]>(
        `
        INSERT INTO bookings (
          code, customer_id, service_id, provider_id,
          status, scheduled_at, address_text, location, notes,
          estimated_price, created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4,
          'pending', $5, $6, ST_SetSRID(ST_MakePoint($7, $8), 4326), $9,
          $10, NOW(), NOW()
        ) RETURNING id, code, status, scheduled_at, estimated_price, provider_id
      `,
        code,
        customerId,
        dto.serviceId,
        isDirectBooking ? BigInt(dto.providerId!) : null, // provider_id for direct booking
        new Date(dto.scheduledAt),
        dto.addressText,
        dto.longitude,
        dto.latitude,
        dto.notes || null,
        basePrice,
      );

      const booking = bookingIdResult[0];
      const bookingId = booking.id;

      // 2. Determine which providers to notify
      let providerIdsToNotify: string[] = [];

      if (isDirectBooking) {
        // Direct booking: Only notify the chosen provider
        providerIdsToNotify = [dto.providerId!.toString()];
      } else {
        // General booking: Find nearby providers by category
        const providers = await this.findNearbyProviders(
          dto.serviceId,
          dto.latitude,
          dto.longitude,
          tx,
        );
        providerIdsToNotify = providers.map((p) =>
          (p as any).user_id.toString(),
        );
      }

      // 3. Return booking info with provider IDs for notification
      return {
        id: booking.id.toString(),
        code: booking.code,
        status: booking.status,
        scheduledAt: booking.scheduled_at,
        estimatedPrice: booking.estimated_price?.toString(),
        providerId: booking.provider_id?.toString() || null,
        isDirectBooking,
        nearbyProviderIds: providerIdsToNotify,
      };
    });
  }

  // Helper: Find nearby providers (multiple) based on their registered service radius
  private async findNearbyProviders(
    serviceId: number,
    latitude: number,
    longitude: number,
    tx?: any,
  ) {
    const prisma = tx || this.prisma;

    // Use each provider's own service_radius_m for filtering
    return await prisma.$queryRawUnsafe(
      `
      SELECT 
        pp.user_id,
        pp.display_name,
        pp.service_radius_m,
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
        AND pp.location IS NOT NULL
        AND ST_DWithin(
          pp.location::geography,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
          COALESCE(pp.service_radius_m, 5000)
        )
      ORDER BY distance ASC
      LIMIT 10
    `,
      longitude,
      latitude,
      serviceId,
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

    // DIRECT BOOKING: If this booking was specifically assigned to this provider
    // Accept it directly (no offer needed), update status to 'accepted'
    if (booking.providerId === providerId) {
      console.log('[acceptBookingRequest] Direct booking - auto accepting');

      const updated = await this.prisma.booking.update({
        where: { id: bookingId },
        data: {
          status: 'accepted',
          actualPrice: providerService.price,
        },
      });

      // Create booking event
      await this.prisma.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'pending',
          newStatus: 'accepted',
          actorUserId: providerId,
          note: 'Provider accepted direct booking',
        },
      });

      return {
        message: 'Đã chấp nhận đặt lịch',
        bookingId: bookingId.toString(),
        status: 'accepted',
        isDirectBooking: true,
      };
    }

    // GENERAL BOOKING: Create offer for customer to choose
    console.log('[acceptBookingRequest] General booking - creating offer');

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
      isDirectBooking: false,
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

    // Get offers using raw SQL with distance calculation
    const offers = await this.prisma.$queryRawUnsafe<any[]>(
      `
      SELECT 
        bo.id,
        bo.booking_id,
        bo.provider_id,
        bo.price,
        bo.status,
        pp.display_name as provider_name,
        pp.rating_avg,
        pp.address as provider_address,
        CASE 
          WHEN b.location IS NOT NULL AND pp.location IS NOT NULL 
          THEN ST_Distance(b.location::geography, pp.location::geography)
          ELSE NULL 
        END as distance
      FROM booking_offers bo
      JOIN provider_profiles pp ON bo.provider_id = pp.user_id
      JOIN bookings b ON bo.booking_id = b.id
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
        providerAddress: o.provider_address,
        rating: o.rating_avg?.toString(),
        price: o.price.toString(),
        status: o.status,
        distance: o.distance ? Math.round(o.distance) : null, // distance in meters
      })),
    };
  }

  // GET /provider/bookings/requests
  // Returns pending bookings that match provider's service categories
  // Handles both: Direct Booking (provider_id = this provider) AND General Booking (category match)
  async getProviderRequests(providerId: bigint) {
    const requests = await this.prisma.$queryRawUnsafe<any[]>(
      `
      SELECT 
        b.id,
        b.code,
        b.status,
        b.scheduled_at,
        b.address_text,
        b.estimated_price,
        b.created_at,
        b.provider_id,
        s.name as service_name,
        sc.name as category_name,
        up.full_name as customer_name,
        CASE 
          WHEN b.location IS NOT NULL AND pp.location IS NOT NULL 
          THEN ST_Distance(b.location::geography, pp.location::geography)
          ELSE NULL 
        END as distance,
        CASE 
          WHEN b.provider_id = $1 THEN 'DIRECT'
          ELSE 'GENERAL'
        END as booking_type,
        CASE WHEN b.provider_id = $1 THEN 0 ELSE 1 END as sort_priority
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      LEFT JOIN service_categories sc ON s.category_id = sc.id
      JOIN user_profiles up ON b.customer_id = up.user_id
      CROSS JOIN provider_profiles pp
      WHERE pp.user_id = $1
        AND b.status = 'pending'
        AND (
          -- Case 1: Direct booking - provider was specifically chosen
          b.provider_id = $1
          
          -- Case 2: General booking - match by category + radius
          OR (
            b.provider_id IS NULL
            AND EXISTS (
              SELECT 1 FROM provider_services ps
              JOIN services ps_svc ON ps.service_id = ps_svc.id
              WHERE ps.provider_user_id = $1
                AND ps.is_active = true
                AND ps.deleted_at IS NULL
                AND ps_svc.category_id = s.category_id
            )
            AND (
              -- Check radius if both locations available
              (b.location IS NOT NULL AND pp.location IS NOT NULL AND ST_DWithin(
                b.location::geography,
                pp.location::geography,
                COALESCE(pp.service_radius_m, 5000)
              ))
              -- Or if no location data, still show (flexible)
              OR b.location IS NULL 
              OR pp.location IS NULL
            )
          )
        )
        -- Haven't already submitted an offer for this booking
        AND NOT EXISTS (
          SELECT 1 FROM booking_offers bo 
          WHERE bo.booking_id = b.id AND bo.provider_id = $1
        )
      ORDER BY sort_priority, b.created_at DESC
      LIMIT 20
    `,
      providerId,
    );

    console.log('[getProviderRequests] providerId:', providerId.toString());
    console.log('[getProviderRequests] Found', requests.length, 'requests');
    if (requests.length > 0) {
      console.log('[getProviderRequests] First request:', requests[0]);
    }

    return {
      requests: requests.map((r) => ({
        id: r.id.toString(),
        code: r.code,
        status: r.status,
        scheduledAt: r.scheduled_at,
        addressText: r.address_text,
        estimatedPrice: r.estimated_price?.toString(),
        serviceName: r.service_name,
        categoryName: r.category_name,
        customerName: r.customer_name,
        distance: r.distance != null ? Math.round(r.distance) : null,
        bookingType: r.booking_type, // 'DIRECT' or 'GENERAL'
        isDirectBooking: r.provider_id != null,
      })),
    };
  }

  // GET /provider/bookings/global - Bookings outside provider's radius but matching their services
  async getGlobalRequests(providerId: bigint) {
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
        ) as distance,
        pp.service_radius_m
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
        AND NOT ST_DWithin(
          b.location::geography,
          pp.location::geography,
          COALESCE(pp.service_radius_m, 5000)
        )
      ORDER BY ST_Distance(b.location::geography, pp.location::geography) ASC
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
        isOutsideRadius: true,
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
          review: {
            select: {
              id: true,
              rating: true,
              comment: true,
              createdAt: true,
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
  // Provider marks service as complete, waits for customer confirmation
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
          status: 'pending_completion', // Wait for customer confirmation
          actualPrice: booking.estimatedPrice,
        },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'in_progress',
          newStatus: 'pending_completion',
          actorUserId: providerId,
          note: 'Provider marked service as complete, awaiting customer confirmation',
        },
      });

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Đã đánh dấu hoàn thành. Đang chờ khách hàng xác nhận.',
      };
    });
  }

  // PATCH /bookings/:id/confirm-completion
  // Customer confirms the service is completed
  async confirmCompletion(customerId: bigint, bookingId: bigint) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { service: true },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.customerId !== customerId) {
      throw new ForbiddenException('Not your booking');
    }

    if (booking.status !== 'pending_completion') {
      throw new BadRequestException('Booking is not pending completion');
    }

    return await this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: 'completed',
          completedAt: new Date(),
        },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'pending_completion',
          newStatus: 'completed',
          actorUserId: customerId,
          note: 'Customer confirmed service completion',
        },
      });

      // Update provider rating if needed (can be done in review step)

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Công việc đã hoàn thành. Vui lòng đánh giá dịch vụ.',
        canReview: true,
      };
    });
  }

  // PATCH /bookings/:id/dispute
  // Customer disputes the service completion
  async disputeBooking(customerId: bigint, bookingId: bigint, reason?: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.customerId !== customerId) {
      throw new ForbiddenException('Not your booking');
    }

    if (booking.status !== 'pending_completion') {
      throw new BadRequestException('Booking is not pending completion');
    }

    return await this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: 'disputed',
        },
      });

      await tx.bookingEvent.create({
        data: {
          bookingId,
          previousStatus: 'pending_completion',
          newStatus: 'disputed',
          actorUserId: customerId,
          note: reason || 'Customer disputed service completion',
        },
      });

      return {
        id: updated.id.toString(),
        status: updated.status,
        message: 'Đã gửi khiếu nại. Chúng tôi sẽ liên hệ với bạn sớm.',
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

      // Get provider user info for displayName
      const providerUser = await tx.user.findUnique({
        where: { id: booking.providerId! },
        include: { profile: true },
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
