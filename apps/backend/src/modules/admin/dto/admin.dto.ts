import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export class ResolveDisputeDto {
    @ApiProperty({ enum: ['customer_favor', 'provider_favor', 'split'] })
    @IsEnum(['customer_favor', 'provider_favor', 'split'])
    resolution: string;

    @ApiProperty({ example: 0 })
    @IsOptional()
    @IsNumber()
    refundAmount: number = 0;

    @ApiProperty({ example: 'Refunded due to poor service' })
    @IsOptional()
    @IsString()
    notes?: string;
}

/**
 * DTO for getting admin dashboard data
 */
export class AdminDashboardQueryDto {
    @ApiPropertyOptional({ example: '2025-12-01', description: 'Start date for analytics' })
    @IsOptional()
    @IsString()
    startDate?: string;

    @ApiPropertyOptional({ example: '2025-12-06', description: 'End date for analytics' })
    @IsOptional()
    @IsString()
    endDate?: string;

    @ApiPropertyOptional({ example: true, description: 'Include detailed breakdown' })
    @IsOptional()
    @Type(() => Boolean)
    detailed?: boolean = false;
}

/**
 * DTO for listing disputes from admin perspective
 */
export class AdminDisputesQueryDto {
    @ApiPropertyOptional({ example: 1, description: 'Page number' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    page?: number = 1;

    @ApiPropertyOptional({ example: 20, description: 'Items per page' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    @Max(100)
    limit?: number = 20;

    @ApiPropertyOptional({
        example: 'open',
        description: 'Filter by status',
        enum: ['open', 'under_review', 'resolved', 'closed']
    })
    @IsOptional()
    @IsEnum(['open', 'under_review', 'resolved', 'closed'])
    status?: string;

    @ApiPropertyOptional({ example: 'createdAt', description: 'Sort by field', enum: ['createdAt', 'status'] })
    @IsOptional()
    @IsEnum(['createdAt', 'status'])
    sortBy?: string = 'createdAt';

    @ApiPropertyOptional({ example: 'desc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortOrder?: 'asc' | 'desc' = 'desc';

    @ApiPropertyOptional({ example: 'pending', description: 'Filter by resolution status', enum: ['pending', 'resolved', 'appealed'] })
    @IsOptional()
    @IsEnum(['pending', 'resolved', 'appealed'])
    resolutionStatus?: string;
}

/**
 * DTO for listing withdrawal requests
 */
export class AdminWithdrawalsQueryDto {
    @ApiPropertyOptional({ example: 1, description: 'Page number' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    page?: number = 1;

    @ApiPropertyOptional({ example: 20, description: 'Items per page' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    @Max(100)
    limit?: number = 20;

    @ApiPropertyOptional({
        example: 'pending',
        description: 'Filter by status',
        enum: ['pending', 'approved', 'rejected', 'processing', 'completed', 'failed']
    })
    @IsOptional()
    @IsEnum(['pending', 'approved', 'rejected', 'processing', 'completed', 'failed'])
    status?: string;

    @ApiPropertyOptional({ example: 'createdAt', description: 'Sort by field', enum: ['createdAt', 'status'] })
    @IsOptional()
    @IsEnum(['createdAt', 'status'])
    sortBy?: string = 'createdAt';

    @ApiPropertyOptional({ example: 'desc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortOrder?: 'asc' | 'desc' = 'desc';

    @ApiPropertyOptional({ example: '2025-12-01', description: 'Start date' })
    @IsOptional()
    @IsString()
    startDate?: string;

    @ApiPropertyOptional({ example: '2025-12-06', description: 'End date' })
    @IsOptional()
    @IsString()
    endDate?: string;
}

/**
 * DTO for approving withdrawal request
 */
export class ApproveWithdrawalDto {
    @ApiProperty({ example: 'Withdrawal approved and processed' })
    @IsNotEmpty()
    @IsString()
    approvalNotes: string;

    @ApiPropertyOptional({ example: 'TXN123456', description: 'External transaction ID' })
    @IsOptional()
    @IsString()
    externalTransactionId?: string;

    @ApiPropertyOptional({ example: 'bank_transfer', description: 'Payment method used' })
    @IsOptional()
    @IsString()
    paymentMethod?: string;
}

/**
 * DTO for rejecting withdrawal request
 */
export class RejectWithdrawalDto {
    @ApiProperty({ example: 'Insufficient verification documents' })
    @IsNotEmpty()
    @IsString()
    rejectionReason: string;

    @ApiPropertyOptional({ example: 'Please resubmit with complete documents' })
    @IsOptional()
    @IsString()
    adminNotes?: string;

    @ApiPropertyOptional({ example: true, description: 'Whether to refund amount to wallet' })
    @IsOptional()
    @Type(() => Boolean)
    refundToWallet?: boolean = true;
}

/**
 * DTO for listing users from admin perspective
 */
export class AdminUsersQueryDto {
    @ApiPropertyOptional({ example: 1, description: 'Page number' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    page?: number = 1;

    @ApiPropertyOptional({ example: 20, description: 'Items per page' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    @Max(100)
    limit?: number = 20;

    @ApiPropertyOptional({ example: 'active', description: 'Filter by status', enum: ['active', 'inactive', 'banned'] })
    @IsOptional()
    @IsEnum(['active', 'inactive', 'banned'])
    status?: string;

    @ApiPropertyOptional({ example: 'customer', description: 'Filter by role', enum: ['customer', 'provider', 'admin'] })
    @IsOptional()
    @IsEnum(['customer', 'provider', 'admin'])
    role?: string;

    @ApiPropertyOptional({ example: 'john@example.com', description: 'Search by email' })
    @IsOptional()
    @IsString()
    email?: string;

    @ApiPropertyOptional({ example: '0901234567', description: 'Search by phone' })
    @IsOptional()
    @IsString()
    phone?: string;

    @ApiPropertyOptional({ example: 'John', description: 'Search by full name' })
    @IsOptional()
    @IsString()
    search?: string;

    @ApiPropertyOptional({ example: 'createdAt', description: 'Sort by field', enum: ['createdAt', 'email', 'status'] })
    @IsOptional()
    @IsEnum(['createdAt', 'email', 'status'])
    sortBy?: string = 'createdAt';

    @ApiPropertyOptional({ example: 'desc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortOrder?: 'asc' | 'desc' = 'desc';
}

/**
 * DTO for listing providers from admin perspective
 */
export class AdminProvidersQueryDto {
    @ApiPropertyOptional({ example: 1, description: 'Page number' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    page?: number = 1;

    @ApiPropertyOptional({ example: 20, description: 'Items per page' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    @Max(100)
    limit?: number = 20;

    @ApiPropertyOptional({
        example: 'verified',
        description: 'Filter by verification status',
        enum: ['unverified', 'pending', 'verified', 'rejected']
    })
    @IsOptional()
    @IsEnum(['unverified', 'pending', 'verified', 'rejected'])
    verificationStatus?: string;

    @ApiPropertyOptional({ example: 4.5, description: 'Minimum rating' })
    @IsOptional()
    @Type(() => Number)
    minRating?: number;

    @ApiPropertyOptional({ example: 'John Service', description: 'Search by display name' })
    @IsOptional()
    @IsString()
    search?: string;

    @ApiPropertyOptional({ example: 'true', description: 'Filter by availability' })
    @IsOptional()
    @Type(() => Boolean)
    isAvailable?: boolean;

    @ApiPropertyOptional({ example: 'rating', description: 'Sort by field', enum: ['ratingAvg', 'createdAt', 'displayName'] })
    @IsOptional()
    @IsEnum(['ratingAvg', 'createdAt', 'displayName'])
    sortBy?: string = 'ratingAvg';

    @ApiPropertyOptional({ example: 'desc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortOrder?: 'asc' | 'desc' = 'desc';
}

/**
 * DTO for banning/unbanning user
 */
export class BanUserDto {
    @ApiProperty({ example: 'ban', description: 'Action to perform', enum: ['ban', 'unban'] })
    @IsEnum(['ban', 'unban'])
    action: 'ban' | 'unban';

    @ApiProperty({ example: 'Violation of terms of service' })
    @IsNotEmpty()
    @IsString()
    reason: string;

    @ApiPropertyOptional({ example: 'Spam and abusive behavior towards providers' })
    @IsOptional()
    @IsString()
    adminNotes?: string;

    @ApiPropertyOptional({ example: 30, description: 'Duration in days (0 = permanent)' })
    @IsOptional()
    @Type(() => Number)
    @Min(0)
    durationDays?: number = 0;
}

/**
 * DTO for verifying/rejecting provider
 */
export class VerifyProviderDto {
    @ApiProperty({ example: 'verified', description: 'Verification action', enum: ['verified', 'rejected'] })
    @IsEnum(['verified', 'rejected'])
    action: 'verified' | 'rejected';

    @ApiProperty({ example: 'All documents verified successfully' })
    @IsNotEmpty()
    @IsString()
    adminNotes: string;

    @ApiPropertyOptional({ example: 'Documents incomplete', description: 'Rejection reason (required if action=rejected)' })
    @IsOptional()
    @IsString()
    rejectionReason?: string;
}

/**
 * DTO for listing bookings from admin perspective
 */
export class AdminBookingsQueryDto {
    @ApiPropertyOptional({ example: 1, description: 'Page number' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    page?: number = 1;

    @ApiPropertyOptional({ example: 20, description: 'Items per page' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    @Max(100)
    limit?: number = 20;

    @ApiPropertyOptional({
        example: 'completed',
        description: 'Filter by status',
        enum: ['pending', 'accepted', 'in_progress', 'completed', 'cancelled', 'disputed']
    })
    @IsOptional()
    @IsEnum(['pending', 'accepted', 'in_progress', 'completed', 'cancelled', 'disputed'])
    status?: string;

    @ApiPropertyOptional({ example: '2025-12-01', description: 'Start date' })
    @IsOptional()
    @IsString()
    startDate?: string;

    @ApiPropertyOptional({ example: '2025-12-06', description: 'End date' })
    @IsOptional()
    @IsString()
    endDate?: string;

    @ApiPropertyOptional({ example: 'customer', description: 'Filter by customer phone/email' })
    @IsOptional()
    @IsString()
    customerSearch?: string;

    @ApiPropertyOptional({ example: 'provider', description: 'Filter by provider phone/email' })
    @IsOptional()
    @IsString()
    providerSearch?: string;

    @ApiPropertyOptional({ example: 'createdAt', description: 'Sort by field', enum: ['createdAt', 'scheduledAt', 'actualPrice', 'status'] })
    @IsOptional()
    @IsEnum(['createdAt', 'scheduledAt', 'actualPrice', 'status'])
    sortBy?: string = 'createdAt';

    @ApiPropertyOptional({ example: 'desc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortOrder?: 'asc' | 'desc' = 'desc';
}

/**
 * DTO for listing payments from admin perspective
 */
export class AdminPaymentsQueryDto {
    @ApiPropertyOptional({ example: 1, description: 'Page number' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    page?: number = 1;

    @ApiPropertyOptional({ example: 20, description: 'Items per page' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    @Max(100)
    limit?: number = 20;

    @ApiPropertyOptional({
        example: 'succeeded',
        description: 'Filter by status',
        enum: ['initiated', 'succeeded', 'failed']
    })
    @IsOptional()
    @IsEnum(['initiated', 'succeeded', 'failed'])
    status?: string;

    @ApiPropertyOptional({ example: 'momo', description: 'Filter by gateway/method' })
    @IsOptional()
    @IsString()
    gateway?: string;

    @ApiPropertyOptional({ example: '2025-12-01', description: 'Start date' })
    @IsOptional()
    @IsString()
    startDate?: string;

    @ApiPropertyOptional({ example: '2025-12-06', description: 'End date' })
    @IsOptional()
    @IsString()
    endDate?: string;

    @ApiPropertyOptional({ example: 100000, description: 'Minimum amount' })
    @IsOptional()
    @Type(() => Number)
    minAmount?: number;

    @ApiPropertyOptional({ example: 10000000, description: 'Maximum amount' })
    @IsOptional()
    @Type(() => Number)
    maxAmount?: number;

    @ApiPropertyOptional({ example: 'createdAt', description: 'Sort by field', enum: ['createdAt', 'amount', 'status'] })
    @IsOptional()
    @IsEnum(['createdAt', 'amount', 'status'])
    sortBy?: string = 'createdAt';

    @ApiPropertyOptional({ example: 'desc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortOrder?: 'asc' | 'desc' = 'desc';
}

/**
 * DTO for listing revenue reports
 */
export class AdminRevenueReportQueryDto {
    @ApiPropertyOptional({ example: '2025-12-01', description: 'Start date for report' })
    @IsOptional()
    @IsString()
    startDate?: string;

    @ApiPropertyOptional({ example: '2025-12-06', description: 'End date for report' })
    @IsOptional()
    @IsString()
    endDate?: string;

    @ApiPropertyOptional({
        example: 'daily',
        description: 'Grouping period',
        enum: ['daily', 'weekly', 'monthly']
    })
    @IsOptional()
    @IsEnum(['daily', 'weekly', 'monthly'])
    groupBy?: 'daily' | 'weekly' | 'monthly' = 'daily';

    @ApiPropertyOptional({ example: 1, description: 'Service category ID to filter' })
    @IsOptional()
    @Type(() => Number)
    categoryId?: number;

    @ApiPropertyOptional({ example: true, description: 'Include service-wise breakdown' })
    @IsOptional()
    @Type(() => Boolean)
    includeServiceBreakdown?: boolean = false;

    @ApiPropertyOptional({ example: true, description: 'Include provider-wise breakdown' })
    @IsOptional()
    @Type(() => Boolean)
    includeProviderBreakdown?: boolean = false;
}

/**
 * DTO for listing services analytics reports
 */
export class AdminServicesReportQueryDto {
    @ApiPropertyOptional({ example: '2025-12-01', description: 'Start date for report' })
    @IsOptional()
    @IsString()
    startDate?: string;

    @ApiPropertyOptional({ example: '2025-12-06', description: 'End date for report' })
    @IsOptional()
    @IsString()
    endDate?: string;

    @ApiPropertyOptional({
        example: 'bookings',
        description: 'Sort by metric',
        enum: ['bookings', 'revenue', 'rating', 'providers']
    })
    @IsOptional()
    @IsEnum(['bookings', 'revenue', 'rating', 'providers'])
    sortBy?: 'bookings' | 'revenue' | 'rating' | 'providers' = 'bookings';

    @ApiPropertyOptional({ example: 'desc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortOrder?: 'asc' | 'desc' = 'desc';

    @ApiPropertyOptional({ example: 20, description: 'Number of top services' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    @Max(100)
    limit?: number = 20;

    @ApiPropertyOptional({ example: 1, description: 'Category ID filter' })
    @IsOptional()
    @Type(() => Number)
    categoryId?: number;
}

/**
 * DTO for listing users analytics reports
 */
export class AdminUsersReportQueryDto {
    @ApiPropertyOptional({ example: '2025-12-01', description: 'Start date for report' })
    @IsOptional()
    @IsString()
    startDate?: string;

    @ApiPropertyOptional({ example: '2025-12-06', description: 'End date for report' })
    @IsOptional()
    @IsString()
    endDate?: string;

    @ApiPropertyOptional({
        example: 'daily',
        description: 'Grouping period',
        enum: ['daily', 'weekly', 'monthly']
    })
    @IsOptional()
    @IsEnum(['daily', 'weekly', 'monthly'])
    groupBy?: 'daily' | 'weekly' | 'monthly' = 'daily';

    @ApiPropertyOptional({
        example: 'newUsers',
        description: 'Sort by metric',
        enum: ['newUsers', 'activeUsers', 'bookings', 'walletValue']
    })
    @IsOptional()
    @IsEnum(['newUsers', 'activeUsers', 'bookings', 'walletValue'])
    sortBy?: 'newUsers' | 'activeUsers' | 'bookings' | 'walletValue' = 'newUsers';

    @ApiPropertyOptional({ example: 'desc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortOrder?: 'asc' | 'desc' = 'desc';

    @ApiPropertyOptional({
        example: 'customer',
        description: 'Filter by user role',
        enum: ['customer', 'provider', 'all']
    })
    @IsOptional()
    @IsEnum(['customer', 'provider', 'all'])
    userRole?: 'customer' | 'provider' | 'all' = 'all';
}

/**
 * DTO for creating system announcements
 */
export class CreateAnnouncementDto {
    @ApiProperty({ example: 'System Maintenance' })
    @IsNotEmpty()
    @IsString()
    title: string;

    @ApiProperty({ example: 'The platform will be down for maintenance on Dec 10' })
    @IsNotEmpty()
    @IsString()
    body: string;

    @ApiPropertyOptional({
        example: 'maintenance',
        description: 'Type of announcement',
        enum: ['maintenance', 'promotion', 'alert', 'general']
    })
    @IsOptional()
    @IsEnum(['maintenance', 'promotion', 'alert', 'general'])
    type?: 'maintenance' | 'promotion' | 'alert' | 'general' = 'general';

    @ApiPropertyOptional({
        example: 'all',
        description: 'Target audience',
        enum: ['all', 'customers', 'providers', 'admins']
    })
    @IsOptional()
    @IsEnum(['all', 'customers', 'providers', 'admins'])
    targetRole?: 'all' | 'customers' | 'providers' | 'admins' = 'all';

    @ApiPropertyOptional({ example: true, description: 'Whether to send notifications' })
    @IsOptional()
    @Type(() => Boolean)
    sendNotification?: boolean = true;

    @ApiPropertyOptional({ example: '2025-12-10T10:00:00Z', description: 'Scheduled time to send' })
    @IsOptional()
    @IsString()
    scheduledAt?: string;
}

/**
 * DTO for listing announcements
 */
export class AdminAnnouncementsQueryDto {
    @ApiPropertyOptional({ example: 1, description: 'Page number' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    page?: number = 1;

    @ApiPropertyOptional({ example: 20, description: 'Items per page' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    @Max(100)
    limit?: number = 20;

    @ApiPropertyOptional({
        example: 'general',
        description: 'Filter by announcement type',
        enum: ['maintenance', 'promotion', 'alert', 'general']
    })
    @IsOptional()
    @IsEnum(['maintenance', 'promotion', 'alert', 'general'])
    type?: string;

    @ApiPropertyOptional({
        example: 'all',
        description: 'Filter by target role',
        enum: ['all', 'customers', 'providers', 'admins']
    })
    @IsOptional()
    @IsEnum(['all', 'customers', 'providers', 'admins'])
    targetRole?: string;

    @ApiPropertyOptional({
        example: 'active',
        description: 'Filter by status',
        enum: ['active', 'scheduled', 'archived']
    })
    @IsOptional()
    @IsEnum(['active', 'scheduled', 'archived'])
    status?: string;

    @ApiPropertyOptional({ example: 'createdAt', description: 'Sort by field', enum: ['createdAt', 'title', 'status'] })
    @IsOptional()
    @IsEnum(['createdAt', 'title', 'status'])
    sortBy?: string = 'createdAt';

    @ApiPropertyOptional({ example: 'desc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortOrder?: 'asc' | 'desc' = 'desc';
}
