import {
    Injectable,
    NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ResolveDisputeDto } from './dto/admin.dto';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class AdminService {
    constructor(private prisma: PrismaService) { }

    /**
     * Resolve dispute
     */
    async resolveDispute(
        disputeId: bigint,
        adminId: bigint,
        dto: ResolveDisputeDto,
    ) {
        const dispute = await this.prisma.dispute.findUnique({
            where: { id: disputeId },
            include: {
                booking: { include: { customer: { include: { wallet: true } } } },
            },
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
                    resolvedByAdminId: adminId,
                    resolvedAt: new Date(),
                    // adminNotes: dto.notes // Schema doesn't have adminNotes yet.
                },
            });

            // Process refund if in favor of customer
            if (dto.resolution === 'customer_favor' && dto.refundAmount > 0) {
                const refundAmount = new Decimal(dto.refundAmount);

                // Create refund transaction
                await tx.walletTransaction.create({
                    data: {
                        walletUserId: dispute.booking.customerId,
                        type: 'refund',
                        amount: refundAmount,
                        balanceAfter: dispute.booking.customer.wallet
                            ? dispute.booking.customer.wallet.balance.plus(refundAmount)
                            : refundAmount, // Should check wallet existence, assuming it exists for now
                        status: 'completed',
                        metadata: {
                            description: `Dispute refund for booking #${dispute.bookingId}`,
                            disputeId: disputeId.toString()
                        },
                    },
                });

                // Update wallet balance
                await tx.wallet.update({
                    where: { userId: dispute.booking.customerId },
                    data: { balance: { increment: refundAmount } },
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
                        refundAmount: dto.refundAmount,
                        notes: dto.notes
                    },
                },
            });

            return { message: 'Dispute resolved successfully' };
        });
    }
}
