import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

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
