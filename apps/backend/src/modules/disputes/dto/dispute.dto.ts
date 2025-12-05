import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsNotEmpty, IsNumber, IsOptional, IsString, IsEnum, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export class GetDisputesDto {
    @ApiPropertyOptional({ example: 1, description: 'Page number' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    page?: number = 1;

    @ApiPropertyOptional({ example: 10, description: 'Items per page' })
    @IsOptional()
    @Type(() => Number)
    @Min(1)
    @Max(100)
    limit?: number = 10;

    @ApiPropertyOptional({ example: 'open', description: 'Filter by status', enum: ['open', 'under_review', 'resolved', 'closed'] })
    @IsOptional()
    @IsEnum(['open', 'under_review', 'resolved', 'closed'])
    status?: string;

    @ApiPropertyOptional({ example: 'desc', description: 'Sort order', enum: ['asc', 'desc'] })
    @IsOptional()
    @IsEnum(['asc', 'desc'])
    sortBy?: 'asc' | 'desc' = 'desc';
}

export class CreateDisputeDto {
    @ApiProperty({ example: 1 })
    @IsNotEmpty()
    @IsNumber()
    bookingId: number;

    @ApiProperty({ example: 'Service not as described' })
    @IsNotEmpty()
    @IsString()
    reason: string;

    @ApiProperty({ example: 'The provider did not clean the kitchen properly.' })
    @IsNotEmpty()
    @IsString()
    description: string;

    @ApiPropertyOptional({ type: [String] })
    @IsOptional()
    @IsArray()
    evidence?: string[];
}

export class GetDisputeDetailDto {
    @ApiPropertyOptional({ example: true, description: 'Include related booking and service data' })
    @IsOptional()
    @Type(() => Boolean)
    includeRelations?: boolean = true;
}

export class UpdateDisputeAppealDto {
    @ApiProperty({ example: 'I disagree with this resolution. Here is why...' })
    @IsNotEmpty()
    @IsString()
    appealReason: string;

    @ApiPropertyOptional({ type: [String], example: ['evidence_url_1', 'evidence_url_2'] })
    @IsOptional()
    @IsArray()
    newEvidence?: string[];
}
