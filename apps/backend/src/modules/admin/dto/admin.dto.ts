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

    @ApiPropertyOptional({ example: 'asc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortBy?: 'asc' | 'desc' = 'desc';

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

    @ApiPropertyOptional({ example: 'asc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortBy?: 'asc' | 'desc' = 'desc';

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
