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
