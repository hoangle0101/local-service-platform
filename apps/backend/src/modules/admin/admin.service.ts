import {
    Injectable,
    NotFoundException,
    BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
    ResolveDisputeDto,
    AdminDashboardQueryDto,
    AdminDisputesQueryDto,
    AdminWithdrawalsQueryDto,
    ApproveWithdrawalDto,
    RejectWithdrawalDto,
} from './dto/admin.dto';
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

    /**
     * Get admin dashboard overview
     * Returns key metrics: total revenue, active bookings, disputes, etc.
     */
    async getDashboard(query: AdminDashboardQueryDto) {
        const startDate = query.startDate ? new Date(query.startDate) : new Date(new Date().setDate(new Date().getDate() - 30));
        const endDate = query.endDate ? new Date(query.endDate) : new Date();

        // Use Promise.all for parallel queries
        const [
            totalUsers,
            activeProviders,
            totalBookings,
            completedBookings,
            totalDisputes,
            openDisputes,
            totalRevenue,
            recentActivity,
        ] = await Promise.all([
            // Total users count
            this.prisma.user.count({
                where: { status: 'active' }
            }),
            // Active providers
            this.prisma.providerProfile.count({
                where: {
                    verificationStatus: 'verified',
                    user: { status: 'active' }
                }
            }),
            // Total bookings in period
            this.prisma.booking.count({
                where: {
                    createdAt: { gte: startDate, lte: endDate }
                }
            }),
            // Completed bookings in period
            this.prisma.booking.count({
                where: {
                    status: 'completed',
                    createdAt: { gte: startDate, lte: endDate }
                }
            }),
            // Total disputes
            this.prisma.dispute.count(),
            // Open disputes
            this.prisma.dispute.count({
                where: { status: 'open' }
            }),
            // Total revenue from completed bookings (sum of actual prices)
            this.prisma.booking.aggregate({
                where: {
                    status: 'completed',
                    createdAt: { gte: startDate, lte: endDate }
                },
                _sum: { actualPrice: true }
            }),
            // Recent bookings (last 10)
            this.prisma.booking.findMany({
                where: {
                    createdAt: { gte: startDate, lte: endDate }
                },
                include: {
                    customer: { select: { id: true, phone: true } },
                    providerUser: { select: { id: true } },
                    service: { select: { name: true } }
                },
                orderBy: { createdAt: 'desc' },
                take: 10
            })
        ]);

        // Calculate completion rate
        const completionRate = totalBookings > 0 ? Math.round((completedBookings / totalBookings) * 100) : 0;

        // Calculate average booking value
        const totalRevenueAmount = totalRevenue._sum.actualPrice || new Decimal(0);
        const avgBookingValue = completedBookings > 0 ? totalRevenueAmount.div(completedBookings).toNumber() : 0;

        return {
            overview: {
                totalUsers,
                activeProviders,
                totalBookings,
                completedBookings,
                completionRate: `${completionRate}%`,
                totalDisputes,
                openDisputes,
                disputeResolutionRate: totalDisputes > 0 ? `${Math.round(((totalDisputes - openDisputes) / totalDisputes) * 100)}%` : 'N/A'
            },
            financials: {
                totalRevenue: totalRevenueAmount.toNumber(),
                avgBookingValue: parseFloat(avgBookingValue.toFixed(2)),
                currency: 'VND'
            },
            period: {
                startDate,
                endDate,
                daysIncluded: Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24))
            },
            ...(query.detailed && {
                recentActivity: recentActivity.map(booking => ({
                    id: booking.id,
                    customerId: booking.customerId,
                    providerId: booking.providerId,
                    service: booking.service.name,
                    status: booking.status,
                    price: booking.actualPrice,
                    createdAt: booking.createdAt
                }))
            })
        };
    }

    /**
     * Get list of disputes from admin perspective
     * Admin can see all disputes with filtering and sorting
     */
    async getDisputesForAdmin(query: AdminDisputesQueryDto) {
        const page = query.page || 1;
        const limit = Math.min(query.limit || 20, 100);
        const skip = (page - 1) * limit;
        const sortBy = query.sortBy === 'asc' ? 'asc' : 'desc';

        // Build where clause with filters
        const where: any = {};

        if (query.status) {
            where.status = query.status;
        }

        if (query.resolutionStatus) {
            if (query.resolutionStatus === 'pending') {
                where.status = { in: ['open', 'under_review'] };
            } else if (query.resolutionStatus === 'resolved') {
                where.status = { in: ['resolved', 'closed'] };
            } else if (query.resolutionStatus === 'appealed') {
                where.status = 'under_review';
            }
        }

        // Parallel queries: get disputes and total count
        const [disputes, total] = await Promise.all([
            this.prisma.dispute.findMany({
                where,
                include: {
                    booking: {
                        select: {
                            id: true,
                            customerId: true,
                            providerId: true,
                            actualPrice: true,
                            status: true,
                            customer: { select: { phone: true } },
                            providerUser: { select: { phone: true } },
                            service: { select: { name: true } }
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
            data: disputes.map(dispute => ({
                id: dispute.id,
                bookingId: dispute.bookingId,
                raisedBy: dispute.raisedBy,
                status: dispute.status,
                reason: dispute.reason,
                resolution: dispute.resolution,
                resolvedByAdminId: dispute.resolvedByAdminId,
                resolvedAt: dispute.resolvedAt,
                createdAt: dispute.createdAt,
                booking: dispute.booking ? {
                    id: dispute.booking.id,
                    customerId: dispute.booking.customerId,
                    providerId: dispute.booking.providerId,
                    price: dispute.booking.actualPrice,
                    bookingStatus: dispute.booking.status,
                    customerPhone: dispute.booking.customer.phone,
                    providerPhone: dispute.booking.providerUser?.phone || null,
                    serviceName: dispute.booking.service.name
                } : null
            })),
            pagination: {
                total,
                page,
                limit,
                totalPages: Math.ceil(total / limit),
                hasNextPage: page < Math.ceil(total / limit)
            }
        };
    }

    /**
     * Get list of withdrawal requests from admin perspective
     * Display pending, approved, rejected withdrawals
     */
    async getWithdrawalsForAdmin(query: AdminWithdrawalsQueryDto) {
        const page = query.page || 1;
        const limit = Math.min(query.limit || 20, 100);
        const skip = (page - 1) * limit;
        const sortBy = query.sortBy === 'asc' ? 'asc' : 'desc';

        // Build where clause
        const where: any = {
            type: 'withdrawal'
        };

        if (query.status) {
            where.status = query.status;
        }

        if (query.startDate || query.endDate) {
            where.createdAt = {};
            if (query.startDate) {
                where.createdAt.gte = new Date(query.startDate);
            }
            if (query.endDate) {
                where.createdAt.lte = new Date(query.endDate);
            }
        }

        // Parallel queries - use walletUserId directly instead of wallet relation
        const [withdrawals, total] = await Promise.all([
            this.prisma.walletTransaction.findMany({
                where,
                skip,
                take: limit,
                orderBy: { createdAt: sortBy }
            }),
            this.prisma.walletTransaction.count({ where })
        ]);

        // Fetch user data separately for better type safety
        const userIds = [...new Set(withdrawals.map(w => w.walletUserId))];
        const users = await this.prisma.user.findMany({
            where: { id: { in: userIds } },
            select: {
                id: true,
                phone: true,
                profile: { select: { fullName: true } }
            }
        });

        const userMap = new Map(users.map(u => [u.id, u]));

        return {
            data: withdrawals.map(withdrawal => {
                const user = userMap.get(withdrawal.walletUserId);
                return {
                    id: withdrawal.id,
                    walletUserId: withdrawal.walletUserId,
                    amount: withdrawal.amount.toNumber(),
                    status: withdrawal.status,
                    createdAt: withdrawal.createdAt,
                    user: user ? {
                        userId: user.id,
                        phone: user.phone,
                        fullName: user.profile?.fullName || 'Unknown'
                    } : null,
                    metadata: withdrawal.metadata as any || {}
                };
            }),
            pagination: {
                total,
                page,
                limit,
                totalPages: Math.ceil(total / limit),
                hasNextPage: page < Math.ceil(total / limit)
            }
        };
    }

    /**
     * Approve withdrawal request
     * Validates request and processes payment
     */
    async approveWithdrawal(transactionId: bigint, adminId: bigint, dto: ApproveWithdrawalDto) {
        const withdrawal = await this.prisma.walletTransaction.findUnique({
            where: { id: transactionId }
        });

        if (!withdrawal) {
            throw new NotFoundException('Withdrawal request not found');
        }

        // Validation checks
        if (withdrawal.type !== 'withdrawal') {
            throw new BadRequestException('Transaction is not a withdrawal request');
        }

        if (withdrawal.status !== 'pending') {
            throw new BadRequestException(`Cannot approve withdrawal with status: ${withdrawal.status}`);
        }

        // Verify sufficient balance
        const wallet = await this.prisma.wallet.findUnique({
            where: { userId: withdrawal.walletUserId }
        });

        if (!wallet || wallet.balance.lessThan(withdrawal.amount)) {
            throw new BadRequestException('Insufficient wallet balance to process withdrawal');
        }

        // Process approval in transaction
        return this.prisma.$transaction(async (tx) => {
            // Update withdrawal status
            const updatedWithdrawal = await tx.walletTransaction.update({
                where: { id: transactionId },
                data: {
                    status: 'completed',
                    metadata: {
                        ...(withdrawal.metadata as any),
                        approvalNotes: dto.approvalNotes,
                        externalTransactionId: dto.externalTransactionId,
                        paymentMethod: dto.paymentMethod,
                        approvedAt: new Date().toISOString(),
                        approvedByAdminId: adminId.toString()
                    }
                }
            });

            // Deduct from wallet balance
            await tx.wallet.update({
                where: { userId: withdrawal.walletUserId },
                data: { balance: { decrement: withdrawal.amount } }
            });

            // Create audit log
            await tx.auditLog.create({
                data: {
                    actorUserId: adminId,
                    action: 'withdrawal_approved',
                    objectType: 'wallet_transaction',
                    objectId: transactionId,
                    detail: {
                        withdrawalId: transactionId.toString(),
                        userId: withdrawal.walletUserId.toString(),
                        amount: withdrawal.amount.toString(),
                        approvalNotes: dto.approvalNotes,
                        externalTransactionId: dto.externalTransactionId
                    }
                }
            });

            return {
                message: 'Withdrawal approved successfully',
                withdrawal: updatedWithdrawal
            };
        });
    }

    /**
     * Reject withdrawal request
     * Optionally refund amount to wallet
     */
    async rejectWithdrawal(transactionId: bigint, adminId: bigint, dto: RejectWithdrawalDto) {
        const withdrawal = await this.prisma.walletTransaction.findUnique({
            where: { id: transactionId }
        });

        if (!withdrawal) {
            throw new NotFoundException('Withdrawal request not found');
        }

        // Validation checks
        if (withdrawal.type !== 'withdrawal') {
            throw new BadRequestException('Transaction is not a withdrawal request');
        }

        if (withdrawal.status !== 'pending') {
            throw new BadRequestException(`Cannot reject withdrawal with status: ${withdrawal.status}`);
        }

        // Process rejection in transaction
        return this.prisma.$transaction(async (tx) => {
            // Update withdrawal status
            const updatedWithdrawal = await tx.walletTransaction.update({
                where: { id: transactionId },
                data: {
                    status: 'failed',
                    metadata: {
                        ...(withdrawal.metadata as any),
                        rejectionReason: dto.rejectionReason,
                        adminNotes: dto.adminNotes,
                        rejectedAt: new Date().toISOString(),
                        rejectedByAdminId: adminId.toString()
                    }
                }
            });

            // Optionally refund to wallet
            if (dto.refundToWallet) {
                await tx.wallet.update({
                    where: { userId: withdrawal.walletUserId },
                    data: { balance: { increment: withdrawal.amount } }
                });
            }

            // Create audit log
            await tx.auditLog.create({
                data: {
                    actorUserId: adminId,
                    action: 'withdrawal_rejected',
                    objectType: 'wallet_transaction',
                    objectId: transactionId,
                    detail: {
                        withdrawalId: transactionId.toString(),
                        userId: withdrawal.walletUserId.toString(),
                        amount: withdrawal.amount.toString(),
                        rejectionReason: dto.rejectionReason,
                        adminNotes: dto.adminNotes,
                        refundedToWallet: dto.refundToWallet
                    }
                }
            });

            return {
                message: 'Withdrawal rejected successfully',
                withdrawal: updatedWithdrawal,
                refunded: dto.refundToWallet
            };
        });
    }
}
