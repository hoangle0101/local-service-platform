import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  OnboardingDto,
  UpdateProviderProfileDto,
  UpdateAvailabilityDto,
  AddServiceDto,
  UpdateProviderServiceDto,
} from './dto/provider.dto';

@Injectable()
export class ProviderService {
  constructor(private prisma: PrismaService) {}

  // POST /provider/onboarding
  async onboarding(userId: bigint, dto: OnboardingDto) {
    // Check if already a provider
    const existing = await this.prisma.providerProfile.findUnique({
      where: { userId },
    });

    if (existing) {
      throw new BadRequestException('Already registered as provider');
    }

    return await this.prisma.$transaction(async (tx) => {
      // Create provider profile
      const provider = await tx.providerProfile.create({
        data: {
          userId,
          displayName: dto.displayName,
          bio: dto.bio,
          skills: dto.skills,
          serviceRadiusM: dto.serviceRadiusM || 5000,
          verificationStatus: 'unverified',
        },
      });

      // Create provider role if not exists
      const providerRole = await tx.role.upsert({
        where: { name: 'provider' },
        update: {},
        create: {
          name: 'provider',
          description: 'Service provider role',
        },
      });

      // Assign provider role to user
      await tx.userRole.upsert({
        where: {
          userId_roleId: {
            userId,
            roleId: providerRole.id,
          },
        },
        update: {},
        create: {
          userId,
          roleId: providerRole.id,
        },
      });

      return {
        userId: provider.userId.toString(),
        displayName: provider.displayName,
        verificationStatus: provider.verificationStatus,
        message: 'Provider profile created successfully',
      };
    });
  }

  // GET /provider/me
  async getProfile(userId: bigint) {
    const provider = await this.prisma.providerProfile.findUnique({
      where: { userId },
      include: {
        user: {
          select: {
            profile: true,
          },
        },
        providerServices: {
          where: {
            deletedAt: null,
          },
          include: {
            service: {
              include: {
                category: true,
              },
            },
          },
        },
      },
    });

    if (!provider) {
      throw new NotFoundException('Provider profile not found');
    }

    return {
      userId: provider.userId.toString(),
      displayName: provider.displayName,
      bio: provider.bio,
      skills: provider.skills,
      ratingAvg: provider.ratingAvg.toString(),
      ratingCount: provider.ratingCount,
      isAvailable: provider.isAvailable,
      verificationStatus: provider.verificationStatus,
      serviceRadiusM: provider.serviceRadiusM,
      services: provider.providerServices.map((ps) => ({
        id: `${ps.providerUserId}-${ps.serviceId}`,
        serviceId: ps.serviceId,
        price: ps.price.toString(),
        currency: ps.currency,
        isActive: ps.isActive,
        service: {
          id: ps.service.id,
          name: ps.service.name,
          category: ps.service.category?.name,
        },
      })),
    };
  }

  // PATCH /provider/me
  async updateProfile(userId: bigint, dto: UpdateProviderProfileDto) {
    const updated = await this.prisma.providerProfile.update({
      where: { userId },
      data: dto,
    });

    return {
      userId: updated.userId.toString(),
      displayName: updated.displayName,
      bio: updated.bio,
      skills: updated.skills,
      serviceRadiusM: updated.serviceRadiusM,
    };
  }

  // PATCH /provider/me/availability
  async updateAvailability(userId: bigint, dto: UpdateAvailabilityDto) {
    const updated = await this.prisma.providerProfile.update({
      where: { userId },
      data: { isAvailable: dto.isAvailable },
    });

    return {
      isAvailable: updated.isAvailable,
      message: `Provider is now ${updated.isAvailable ? 'available' : 'unavailable'}`,
    };
  }

  // GET /provider/services
  async getServices(userId: bigint) {
    const services = await this.prisma.providerService.findMany({
      where: {
        providerUserId: userId,
        deletedAt: null,
      },
      include: {
        service: {
          include: {
            category: true,
          },
        },
      },
    });

    return services.map((ps) => ({
      id: `${ps.providerUserId}-${ps.serviceId}`,
      serviceId: ps.serviceId,
      price: ps.price.toString(),
      currency: ps.currency,
      isActive: ps.isActive,
      service: {
        id: ps.service.id,
        name: ps.service.name,
        description: ps.service.description,
        basePrice: ps.service.basePrice.toString(),
        category: ps.service.category
          ? {
              id: ps.service.category.id,
              name: ps.service.category.name,
            }
          : null,
      },
    }));
  }

  // POST /provider/services
  async addService(userId: bigint, dto: AddServiceDto) {
    // Check if service exists
    const service = await this.prisma.service.findUnique({
      where: { id: dto.serviceId },
    });

    if (!service) {
      throw new NotFoundException('Service not found');
    }

    // Check if already added
    const existing = await this.prisma.providerService.findUnique({
      where: {
        providerUserId_serviceId: {
          providerUserId: userId,
          serviceId: dto.serviceId,
        },
      },
    });

    if (existing && !existing.deletedAt) {
      throw new BadRequestException('Service already added');
    }

    // Add or restore service
    const providerService = await this.prisma.providerService.upsert({
      where: {
        providerUserId_serviceId: {
          providerUserId: userId,
          serviceId: dto.serviceId,
        },
      },
      update: {
        price: dto.price,
        currency: dto.currency || 'VND',
        isActive: true,
        deletedAt: null,
      },
      create: {
        providerUserId: userId,
        serviceId: dto.serviceId,
        price: dto.price,
        currency: dto.currency || 'VND',
        isActive: true,
      },
      include: {
        service: true,
      },
    });

    return {
      id: `${providerService.providerUserId}-${providerService.serviceId}`,
      serviceId: providerService.serviceId,
      price: providerService.price.toString(),
      currency: providerService.currency,
      service: {
        id: providerService.service.id,
        name: providerService.service.name,
      },
      message: 'Service added successfully',
    };
  }

  // PATCH /provider/services/:serviceId
  async updateService(userId: bigint, serviceId: number, dto: UpdateProviderServiceDto) {
    const updated = await this.prisma.providerService.update({
      where: {
        providerUserId_serviceId: {
          providerUserId: userId,
          serviceId,
        },
      },
      data: dto,
    });

    return {
      id: `${updated.providerUserId}-${updated.serviceId}`,
      price: updated.price.toString(),
      isActive: updated.isActive,
      message: 'Service updated successfully',
    };
  }

  // DELETE /provider/services/:serviceId
  async removeService(userId: bigint, serviceId: number) {
    await this.prisma.providerService.update({
      where: {
        providerUserId_serviceId: {
          providerUserId: userId,
          serviceId,
        },
      },
      data: {
        deletedAt: new Date(),
        isActive: false,
      },
    });

    return {
      message: 'Service removed successfully',
    };
  }

  // GET /provider/statistics
  async getStatistics(userId: bigint) {
    const [totalBookings, completedBookings, earnings, provider] = await Promise.all([
      // Total bookings
      this.prisma.booking.count({
        where: { providerId: userId },
      }),
      // Completed bookings
      this.prisma.booking.count({
        where: { providerId: userId, status: 'completed' },
      }),
      // Total earnings (completed bookings)
      this.prisma.booking.aggregate({
        where: {
          providerId: userId,
          status: 'completed',
        },
        _sum: {
          providerEarning: true,
        },
      }),
      // Provider profile
      this.prisma.providerProfile.findUnique({
        where: { userId },
      }),
    ]);

    return {
      totalBookings,
      completedBookings,
      totalEarnings: earnings._sum?.providerEarning?.toString() || '0',
      ratingAvg: provider?.ratingAvg.toString() || '0',
      ratingCount: provider?.ratingCount || 0,
    };
  }

  // PATCH /provider/me/location
  async updateLocation(userId: bigint, latitude: number, longitude: number, addressText?: string) {
    // Verify provider profile exists
    const provider = await this.prisma.providerProfile.findUnique({
      where: { userId },
    });

    if (!provider) {
      throw new NotFoundException('Provider profile not found');
    }

    // Validate coordinates
    if (latitude < -90 || latitude > 90) {
      throw new BadRequestException('Invalid latitude. Must be between -90 and 90');
    }

    if (longitude < -180 || longitude > 180) {
      throw new BadRequestException('Invalid longitude. Must be between -180 and 180');
    }

    // Update location using PostGIS
    await this.prisma.$executeRawUnsafe(
      `
      UPDATE provider_profiles
      SET location = ST_SetSRID(ST_MakePoint($1, $2), 4326),
          updated_at = NOW()
      WHERE user_id = $3
    `,
      longitude,
      latitude,
      userId,
    );

    return {
      message: 'Location updated successfully',
      latitude,
      longitude,
      addressText,
    };
  }
}
