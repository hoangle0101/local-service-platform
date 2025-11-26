import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PresignedUrlDto {
  @ApiProperty({ example: 'avatar.jpg' })
  @IsNotEmpty()
  @IsString()
  filename: string;

  @ApiProperty({ example: 'image/jpeg' })
  @IsNotEmpty()
  @IsString()
  contentType: string;
}

export class UploadResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  url: string;

  @ApiProperty()
  category: string | null;

  @ApiProperty()
  size: number | null;
}
