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
    AdminUsersQueryDto,
    AdminProvidersQueryDto,
    BanUserDto,
    VerifyProviderDto,
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

    /**
     * Get list of users from admin perspective
     * Admin can see all users with filtering, searching, and pagination
     */
    async getUsers(query: AdminUsersQueryDto) {
        const page = query.page || 1;
        const limit = Math.min(query.limit || 20, 100);
        const skip = (page - 1) * limit;

        // Build where clause with all filters
        const where: any = {};

        // Filter by status
        if (query.status) {
            where.status = query.status;
        }

        // Filter by role
        if (query.role) {
            where.userRoles = {
                some: {
                    role: { name: query.role }
                }
            };
        }

        // Search by email
        if (query.email) {
            where.email = { contains: query.email, mode: 'insensitive' };
        }

        // Search by phone
        if (query.phone) {
            where.phone = { contains: query.phone, mode: 'insensitive' };
        }

        // Search by full name
        if (query.search) {
            where.profile = {
                fullName: { contains: query.search, mode: 'insensitive' }
            };
        }

        // Determine sort order
        const sortOrder = query.sortOrder === 'asc' ? 'asc' : 'desc';
        const sortBy = query.sortBy || 'createdAt';

        const orderBy: any = {};
        orderBy[sortBy] = sortOrder;

        // Execute parallel queries
        const [users, total] = await Promise.all([
            this.prisma.user.findMany({
                where,
                skip,
                take: limit,
                select: {
                    id: true,
                    phone: true,
                    email: true,
                    status: true,
                    isVerified: true,
                    lastLoginAt: true,
                    createdAt: true,
                    updatedAt: true,
                    profile: {
                        select: {
                            fullName: true,
                            avatarUrl: true,
                        }
                    },
                    userRoles: {
                        select: {
                            role: { select: { name: true } }
                        }
                    },
                    _count: {
                        select: { bookingsCustomer: true, bookingsProvider: true }
                    }
                },
                orderBy
            }),
            this.prisma.user.count({ where })
        ]);

        return {
            data: users.map(user => ({
                id: user.id.toString(),
                phone: user.phone,
                email: user.email,
                fullName: user.profile?.fullName || 'Unknown',
                avatarUrl: user.profile?.avatarUrl,
                status: user.status,
                isVerified: user.isVerified,
                roles: user.userRoles.map(ur => ur.role.name),
                bookingsAsCustomer: user._count.bookingsCustomer,
                bookingsAsProvider: user._count.bookingsProvider,
                lastLoginAt: user.lastLoginAt,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt
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
     * Get list of providers from admin perspective
     * Admin can see all providers with stats and filtering
     */
    async getProviders(query: AdminProvidersQueryDto) {
        const page = query.page || 1;
        const limit = Math.min(query.limit || 20, 100);
        const skip = (page - 1) * limit;

        // Build where clause
        const where: any = {};

        // Filter by verification status
        if (query.verificationStatus) {
            where.verificationStatus = query.verificationStatus;
        }

        // Filter by minimum rating
        if (query.minRating !== undefined) {
            where.ratingAvg = { gte: new Decimal(query.minRating) };
        }

        // Filter by availability
        if (query.isAvailable !== undefined) {
            where.isAvailable = query.isAvailable;
        }

        // Search by display name or user phone
        if (query.search) {
            where.OR = [
                { displayName: { contains: query.search, mode: 'insensitive' } },
                { user: { phone: { contains: query.search, mode: 'insensitive' } } }
            ];
        }

        // Determine sort order
        const sortOrder = query.sortOrder === 'asc' ? 'asc' : 'desc';
        const sortBy = query.sortBy || 'ratingAvg';

        const orderBy: any = {};
        orderBy[sortBy] = sortOrder;

        // Execute parallel queries
        const [providers, total] = await Promise.all([
            this.prisma.providerProfile.findMany({
                where,
                skip,
                take: limit,
                include: {
                    user: {
                        select: {
                            id: true,
                            phone: true,
                            email: true,
                            profile: {
                                select: {
                                    fullName: true,
                                    avatarUrl: true
                                }
                            }
                        }
                    },
                    providerServices: true
                },
                orderBy
            }),
            this.prisma.providerProfile.count({ where })
        ]);

        // Fetch booking statistics for providers
        const providerIds = providers.map(p => p.userId);
        const bookingStats = await this.prisma.booking.groupBy({
            by: ['providerId'],
            where: { providerId: { in: providerIds } },
            _count: true,
            _sum: { providerEarning: true }
        });

        const statsMap = new Map(
            bookingStats.map(stat => [stat.providerId?.toString(), {
                totalBookings: stat._count,
                totalEarnings: stat._sum.providerEarning
            }])
        );

        return {
            data: providers.map(provider => {
                const stats = statsMap.get(provider.userId.toString()) || { totalBookings: 0, totalEarnings: 0 };
                const earnings = stats.totalEarnings instanceof Decimal
                    ? stats.totalEarnings.toNumber()
                    : (typeof stats.totalEarnings === 'number' ? stats.totalEarnings : 0);

                return {
                    userId: provider.userId.toString(),
                    displayName: provider.displayName,
                    bio: provider.bio,
                    phone: provider.user.phone,
                    email: provider.user.email,
                    fullName: provider.user.profile?.fullName,
                    avatarUrl: provider.user.profile?.avatarUrl,
                    rating: {
                        average: provider.ratingAvg.toNumber(),
                        count: provider.ratingCount
                    },
                    isAvailable: provider.isAvailable,
                    verificationStatus: provider.verificationStatus,
                    totalServices: provider.providerServices.length,
                    totalBookings: stats.totalBookings,
                    totalEarnings: earnings,
                    createdAt: provider.createdAt
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
     * Ban or unban a user
     * Validates user exists and updates status
     */
    async banUser(userId: bigint, adminId: bigint, dto: BanUserDto) {
        const user = await this.prisma.user.findUnique({
            where: { id: userId }
        });

        if (!user) {
            throw new NotFoundException('User not found');
        }

        // Check if trying to ban an already banned user
        if (dto.action === 'ban' && user.status === 'banned') {
            throw new BadRequestException('User is already banned');
        }

        // Check if trying to unban an active user
        if (dto.action === 'unban' && user.status === 'active') {
            throw new BadRequestException('User is already active');
        }

        return this.prisma.$transaction(async (tx) => {
            // Update user status
            const newStatus = dto.action === 'ban' ? 'banned' : 'active';
            const updatedUser = await tx.user.update({
                where: { id: userId },
                data: { status: newStatus }
            });

            // Create audit log
            await tx.auditLog.create({
                data: {
                    actorUserId: adminId,
                    action: `user_${dto.action}`,
                    objectType: 'user',
                    objectId: userId,
                    detail: {
                        userId: userId.toString(),
                        action: dto.action,
                        reason: dto.reason,
                        adminNotes: dto.adminNotes,
                        durationDays: dto.durationDays
                    }
                }
            });

            // Create notification for user
            const action = dto.action === 'ban' ? 'banned' : 'unbanned';
            const message = dto.action === 'ban'
                ? `Your account has been banned. Reason: ${dto.reason}`
                : 'Your account has been unbanned and is now active';

            await tx.notification.create({
                data: {
                    userId: userId,
                    title: `Account ${action}`,
                    body: message,
                    type: 'system',
                    payload: {
                        action: dto.action,
                        reason: dto.reason
                    },
                    isRead: false
                }
            });

            return {
                message: `User ${action} successfully`,
                userId: userId.toString(),
                status: newStatus,
                reason: dto.reason
            };
        });
    }

    /**
     * Verify or reject a provider
     * Updates provider verification status
     */
    async verifyProvider(userId: bigint, adminId: bigint, dto: VerifyProviderDto) {
        const provider = await this.prisma.providerProfile.findUnique({
            where: { userId },
            include: { user: true }
        });

        if (!provider) {
            throw new NotFoundException('Provider profile not found');
        }

        // Validate rejection reason is provided if rejecting
        if (dto.action === 'rejected' && !dto.rejectionReason) {
            throw new BadRequestException('Rejection reason is required when rejecting provider');
        }

        return this.prisma.$transaction(async (tx) => {
            // Update provider verification status
            const updatedProvider = await tx.providerProfile.update({
                where: { userId },
                data: {
                    verificationStatus: dto.action
                }
            });

            // Create audit log
            await tx.auditLog.create({
                data: {
                    actorUserId: adminId,
                    action: `provider_${dto.action}`,
                    objectType: 'provider_profile',
                    objectId: userId,
                    detail: {
                        userId: userId.toString(),
                        action: dto.action,
                        adminNotes: dto.adminNotes,
                        rejectionReason: dto.rejectionReason
                    }
                }
            });

            // Create notification for provider
            const title = dto.action === 'verified'
                ? 'Provider Account Verified'
                : 'Provider Application Rejected';

            const body = dto.action === 'verified'
                ? `Congratulations! Your provider account has been verified. You can now accept bookings.`
                : `Your provider application has been rejected. Reason: ${dto.rejectionReason}`;

            await tx.notification.create({
                data: {
                    userId: userId,
                    title,
                    body,
                    type: 'system',
                    payload: {
                        action: dto.action,
                        adminNotes: dto.adminNotes,
                        rejectionReason: dto.rejectionReason
                    },
                    isRead: false
                }
            });

            return {
                message: `Provider ${dto.action} successfully`,
                userId: userId.toString(),
                verificationStatus: dto.action,
                adminNotes: dto.adminNotes
            };
        });
    }
}
