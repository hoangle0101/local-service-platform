import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { UploadService } from './upload.service';
import { SettingsService } from './settings.service';
import { PresignedUrlDto } from './dto/system.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('System')
@Controller('system')
export class SystemController {
  constructor(
    private uploadService: UploadService,
    private settingsService: SettingsService,
  ) {}

  @Post('upload')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload file (image or document)' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  async uploadFile(
    @CurrentUser() user: any,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.uploadService.uploadFile(BigInt(user.userId), file);
  }

  @Post('upload/presigned-url')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get presigned URL for file upload' })
  async getPresignedUrl(
    @CurrentUser() user: any,
    @Body() dto: PresignedUrlDto,
  ) {
    return this.uploadService.getPresignedUrl(
      BigInt(user.userId),
      dto.filename,
      dto.contentType,
    );
  }

  @Get('settings/public')
  @ApiOperation({ summary: 'Get public settings' })
  async getPublicSettings() {
    return this.settingsService.getPublicSettings();
  }
}
