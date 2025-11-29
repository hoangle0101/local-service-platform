import {
    BadRequestException,
    Injectable,
    NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateDisputeDto } from './dto/dispute.dto';

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
}
