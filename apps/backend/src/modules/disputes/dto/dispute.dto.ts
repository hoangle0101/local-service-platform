import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

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
