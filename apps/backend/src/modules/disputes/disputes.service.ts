import {
    BadRequestException,
    Injectable,
    NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateDisputeDto, GetDisputesDto } from './dto/dispute.dto';

@Injectable()
export class DisputesService {
    constructor(private prisma: PrismaService) { }

    /**
     * Create dispute
     */
    async createDispute(userId: bigint, dto: CreateDisputeDto) {
        const booking = await this.prisma.booking.findUnique({
            where: { id: BigInt(dto.bookingId) },
        });

        if (!booking) {
            throw new NotFoundException('Booking not found');
        }

        if (booking.customerId !== userId) {
            throw new NotFoundException('Booking not found');
        }

        // Can only dispute completed bookings
        if (booking.status !== 'completed') {
            throw new BadRequestException('Can only dispute completed bookings');
        }

        // Check if already disputed
        const existing = await this.prisma.dispute.findFirst({
            where: { bookingId: BigInt(dto.bookingId) },
        });

        if (existing) {
            throw new BadRequestException('Dispute already exists for this booking');
        }

        return this.prisma.$transaction(async (tx) => {
            // Create dispute
            const dispute = await tx.dispute.create({
                data: {
                    bookingId: BigInt(dto.bookingId),
                    raisedBy: userId,
                    reason: dto.reason,
                    // description: dto.description, // Schema doesn't have description yet. Assuming reason covers it or schema update needed.
                    // evidence: dto.evidence // Schema doesn't have evidence yet.
                    // For now, mapping description to reason if needed or just using reason.
                    // Let's append description to reason if schema is strict.
                    // Or wait, schema has `reason` (Text).
                    // Let's just use reason.
                    status: 'open',
                },
            });

            // Update booking status
            await tx.booking.update({
                where: { id: booking.id },
                data: { status: 'disputed' }
            });

            return dispute;
        });
    }

    /**
     * Get list of disputes for current user
     * User can see disputes they raised or disputes for their bookings (if provider)
     */
    async getDisputesList(userId: bigint, query: GetDisputesDto) {
        const page = query.page || 1;
        const limit = query.limit || 10;
        const skip = (page - 1) * limit;
        const sortBy = query.sortBy === 'asc' ? 'asc' : 'desc';

        // Build filter
        const where: any = {
            OR: [
                { raisedBy: userId }, // Disputes raised by user
                {
                    booking: {
                        OR: [
                            { customerId: userId }, // Disputes on bookings where user is customer
                            { providerId: userId }, // Disputes on bookings where user is provider
                        ]
                    }
                }
            ]
        };

        // Add status filter if provided
        if (query.status) {
            where.status = query.status;
        }

        // Fetch disputes with pagination
        const [disputes, total] = await Promise.all([
            this.prisma.dispute.findMany({
                where,
                include: {
                    booking: {
                        select: {
                            id: true,
                            customerId: true,
                            providerId: true,
                            serviceId: true,
                            status: true,
                            service: {
                                select: {
                                    name: true,
                                }
                            }
                        }
                    }
                },
                skip,
                take: limit,
                orderBy: { createdAt: sortBy }
            }),
            this.prisma.dispute.count({ where })
        ]);

        return {
            data: disputes,
            pagination: {
                total,
                page,
                limit,
                totalPages: Math.ceil(total / limit),
                hasNextPage: page < Math.ceil(total / limit)
            }
        };
    }
}
