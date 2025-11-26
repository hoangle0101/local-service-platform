import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { ProviderService } from './provider.service';
import {
  OnboardingDto,
  UpdateProviderProfileDto,
  UpdateAvailabilityDto,
  AddServiceDto,
  UpdateServiceDto,
} from './dto/provider.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Provider')
@Controller('provider')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ProviderController {
  constructor(private providerService: ProviderService) {}

  @Post('onboarding')
  @ApiOperation({ summary: 'Register as provider' })
  async onboarding(@CurrentUser() user: any, @Body() dto: OnboardingDto) {
    return this.providerService.onboarding(BigInt(user.userId), dto);
  }

  @Get('me')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Get provider profile' })
  async getProfile(@CurrentUser() user: any) {
    return this.providerService.getProfile(BigInt(user.userId));
  }

  @Patch('me')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Update provider profile' })
  async updateProfile(
    @CurrentUser() user: any,
    @Body() dto: UpdateProviderProfileDto,
  ) {
    return this.providerService.updateProfile(BigInt(user.userId), dto);
  }

  @Patch('me/availability')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Update availability status' })
  async updateAvailability(
    @CurrentUser() user: any,
    @Body() dto: UpdateAvailabilityDto,
  ) {
    return this.providerService.updateAvailability(BigInt(user.userId), dto);
  }

  @Get('services')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Get provider services' })
  async getServices(@CurrentUser() user: any) {
    return this.providerService.getServices(BigInt(user.userId));
  }

  @Post('services')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Add service to provider' })
  async addService(@CurrentUser() user: any, @Body() dto: AddServiceDto) {
    return this.providerService.addService(BigInt(user.userId), dto);
  }

  @Patch('services/:serviceId')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Update provider service' })
  @ApiParam({ name: 'serviceId', example: 1 })
  async updateService(
    @CurrentUser() user: any,
    @Param('serviceId', ParseIntPipe) serviceId: number,
    @Body() dto: UpdateServiceDto,
  ) {
    return this.providerService.updateService(BigInt(user.userId), serviceId, dto);
  }

  @Delete('services/:serviceId')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Remove service from provider' })
  @ApiParam({ name: 'serviceId', example: 1 })
  async removeService(
    @CurrentUser() user: any,
    @Param('serviceId', ParseIntPipe) serviceId: number,
  ) {
    return this.providerService.removeService(BigInt(user.userId), serviceId);
  }

  @Get('statistics')
  @UseGuards(RolesGuard)
  @Roles('provider')
  @ApiOperation({ summary: 'Get provider statistics' })
  async getStatistics(@CurrentUser() user: any) {
    return this.providerService.getStatistics(BigInt(user.userId));
  }
}
