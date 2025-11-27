import {
    Injectable,
    NotFoundException,
    BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { DepositDto, WithdrawDto } from './dto';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class WalletsService {
    constructor(private prisma: PrismaService) { }

    /**
     * Get wallet balance for a user
     */
    async getBalance(userId: bigint) {
        const wallet = await this.prisma.wallet.findUnique({
            where: { userId },
            include: {
                _count: {
                    select: { transactions: true },
                },
            },
        });

        if (!wallet) {
            throw new NotFoundException('Wallet not found');
        }

        return {
            balance: wallet.balance.toString(),
            currency: wallet.currency,
            totalTransactions: wallet._count.transactions,
            createdAt: wallet.createdAt,
        };
    }

    /**
     * Get transaction history
     */
    async getTransactions(
        userId: bigint,
        page: number = 1,
        limit: number = 20,
    ) {
        const wallet = await this.prisma.wallet.findUnique({
            where: { userId },
        });

        if (!wallet) {
            throw new NotFoundException('Wallet not found');
        }

        const skip = (page - 1) * limit;

        const [transactions, total] = await Promise.all([
            this.prisma.walletTransaction.findMany({
                where: { walletUserId: userId },
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit,
            }),
            this.prisma.walletTransaction.count({
                where: { walletUserId: userId },
            }),
        ]);

        return {
            data: transactions.map((tx) => ({
                ...tx,
                amount: tx.amount.toString(),
                balanceAfter: tx.balanceAfter.toString(),
            })),
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit),
            },
        };
    }

    /**
     * Deposit money to wallet (creates pending payment)
     */
    async deposit(userId: bigint, dto: DepositDto) {
        const wallet = await this.prisma.wallet.findUnique({
            where: { userId },
        });

        if (!wallet) {
            throw new NotFoundException('Wallet not found');
        }

        return this.prisma.$transaction(async (tx) => {
            // Create wallet transaction (pending - will be completed when payment succeeds)
            const transaction = await tx.walletTransaction.create({
                data: {
                    walletUserId: userId,
                    type: 'deposit',
                    amount: new Decimal(dto.amount),
                    balanceAfter: wallet.balance, // Will be updated when payment completes
                    status: 'pending', // Explicitly set to pending for deposits
                    metadata: {
                        gateway: dto.gateway,
                        initiatedAt: new Date().toISOString(),
                    },
                },
            });

            // Create payment record
            const payment = await tx.payment.create({
                data: {
                    amount: new Decimal(dto.amount),
                    currency: 'VND',
                    method: dto.gateway === 'momo' ? 'momo' : dto.gateway === 'bank_transfer' ? 'bank_transfer' : 'card',
                    gateway: dto.gateway,
                    gatewayTxId: `pending_${transaction.id}_${Date.now()}`, // Temporary, will be updated by webhook
                    environment: process.env.NODE_ENV === 'production' ? 'production' : 'development',
                    status: 'initiated',
                    payload: {
                        walletTransactionId: transaction.id.toString(),
                        userId: userId.toString(),
                        type: 'deposit',
                    },
                },
            });

            // Link payment to transaction
            await tx.walletTransaction.update({
                where: { id: transaction.id },
                data: { relatedPaymentId: payment.id },
            });

            // Generate payment URL (mock for now)
            const paymentUrl = this.generatePaymentUrl(
                payment.id,
                dto.gateway,
                dto.amount,
            );

            return {
                transactionId: transaction.id.toString(),
                paymentId: payment.id.toString(),
                paymentUrl,
                amount: dto.amount,
                gateway: dto.gateway,
                status: 'pending',
                message: 'Please complete payment at the provided URL',
            };
        });
    }

    /**
     * Withdraw money from wallet
     */
    async withdraw(userId: bigint, dto: WithdrawDto) {
        const wallet = await this.prisma.wallet.findUnique({
            where: { userId },
        });

        if (!wallet) {
            throw new NotFoundException('Wallet not found');
        }

        // Check balance
        if (wallet.balance.lessThan(new Decimal(dto.amount))) {
            throw new BadRequestException(
                `Insufficient balance. Available: ${wallet.balance} VND`,
            );
        }

        // Check daily withdrawal limit
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const todayWithdrawals = await this.prisma.walletTransaction.aggregate({
            where: {
                walletUserId: userId,
                type: 'withdrawal',
                status: { in: ['pending', 'completed'] },
                createdAt: { gte: today },
            },
            _sum: { amount: true },
        });

        const dailyLimit = 10000000; // 10M VND
        const totalToday = todayWithdrawals._sum.amount || new Decimal(0);

        if (totalToday.plus(dto.amount).greaterThan(new Decimal(dailyLimit))) {
            throw new BadRequestException(
                `Daily withdrawal limit exceeded. Limit: ${dailyLimit} VND, Used today: ${totalToday} VND`,
            );
        }

        return this.prisma.$transaction(async (tx) => {
            // Deduct balance immediately
            const updatedWallet = await tx.wallet.update({
                where: { userId: wallet.userId },
                data: { balance: { decrement: dto.amount } },
            });

            // Create withdrawal transaction
            const transaction = await tx.walletTransaction.create({
                data: {
                    walletUserId: userId,
                    type: 'withdrawal',
                    amount: new Decimal(dto.amount),
                    balanceAfter: updatedWallet.balance,
                    status: 'pending', // Pending admin approval
                    metadata: {
                        bankAccount: dto.bankAccount,
                        bankName: dto.bankName,
                        requestedAt: new Date().toISOString(),
                    },
                },
            });

            // Auto-approve if < 1M VND
            if (dto.amount < 1000000) {
                await tx.walletTransaction.update({
                    where: { id: transaction.id },
                    data: { status: 'completed' },
                });

                // Create payout payment record
                const payment = await tx.payment.create({
                    data: {
                        amount: new Decimal(dto.amount),
                        currency: 'VND',
                        method: 'bank_transfer',
                        gateway: 'bank_transfer',
                        gatewayTxId: `withdraw_${transaction.id}_${Date.now()}`,
                        environment: process.env.NODE_ENV === 'production' ? 'production' : 'development',
                        status: 'succeeded',
                        payload: {
                            userId: userId.toString(),
                            type: 'withdrawal',
                            walletTransactionId: transaction.id.toString(),
                            bankAccount: dto.bankAccount,
                            bankName: dto.bankName,
                        },
                    },
                });

                // Link payment to transaction
                await tx.walletTransaction.update({
                    where: { id: transaction.id },
                    data: { relatedPaymentId: payment.id },
                });

                return {
                    message: 'Withdrawal processed successfully',
                    transactionId: transaction.id.toString(),
                    amount: dto.amount,
                    status: 'completed',
                    bankAccount: dto.bankAccount,
                    bankName: dto.bankName,
                };
            }

            // Require admin approval for >= 1M
            return {
                message: 'Withdrawal request submitted for approval',
                transactionId: transaction.id.toString(),
                amount: dto.amount,
                status: 'pending',
                note: 'Large withdrawals require admin approval (1-2 business days)',
            };
        });
    }

    /**
     * Generate payment URL (mock implementation)
     * In production: integrate with real payment gateway APIs
     */
    private generatePaymentUrl(
        paymentId: bigint,
        gateway: string,
        amount: number,
    ): string {
        const baseUrl = process.env.APP_URL || 'http://localhost:3000';

        // Mock payment URLs - in production, call gateway API
        switch (gateway) {
            case 'momo':
                return `https://test-payment.momo.vn/v2/gateway/pay?partnerCode=MOCK&orderId=${paymentId}&amount=${amount}&returnUrl=${baseUrl}/api/v1/payments/callback`;
            case 'stripe':
                return `https://checkout.stripe.com/pay/cs_test_${paymentId}`;
            case 'bank_transfer':
                return `${baseUrl}/api/v1/payments/bank-transfer-info/${paymentId}`;
            default:
                return `${baseUrl}/api/v1/payments/checkout/${paymentId}`;
        }
    }
}
