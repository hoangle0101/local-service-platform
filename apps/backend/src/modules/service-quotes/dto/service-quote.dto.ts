import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsNumber,
  IsArray,
  IsOptional,
  ValidateNested,
  Min,
  IsInt,
} from 'class-validator';
import { Type } from 'class-transformer';

export class QuoteItemDto {
  @ApiProperty({ example: 'Thay gas máy lạnh' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ example: 350000 })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsInt()
  @Min(1)
  quantity: number;
}

export class CreateServiceQuoteDto {
  @ApiProperty({
    example:
      'Máy lạnh không lạnh, gas yếu, cần bổ sung gas và vệ sinh dàn lạnh',
  })
  @IsNotEmpty()
  @IsString()
  diagnosis: string;

  @ApiProperty({
    type: [QuoteItemDto],
    example: [{ name: 'Bơm gas R32', price: 400000, quantity: 1 }],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => QuoteItemDto)
  items: QuoteItemDto[];

  @ApiProperty({ example: 150000, description: 'Công sửa chữa' })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  laborCost: number;

  @ApiPropertyOptional({ example: '3 tháng bảo hành gas' })
  @IsOptional()
  @IsString()
  warranty?: string;

  @ApiPropertyOptional({
    example: 60,
    description: 'Thời gian ước tính (phút)',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  estimatedTime?: number;

  @ApiPropertyOptional({ example: ['https://storage.com/image1.jpg'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];

  @ApiPropertyOptional({
    example: 'Khách hàng cần xác nhận trước khi thay thế linh kiện',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class AcceptQuoteDto {
  @ApiPropertyOptional({ example: 'Đồng ý với báo giá' })
  @IsOptional()
  @IsString()
  customerNote?: string;
}

export class RejectQuoteDto {
  @ApiProperty({ example: 'Giá quá cao, tôi sẽ tìm thợ khác' })
  @IsNotEmpty()
  @IsString()
  reason: string;
}
