import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { BookingsService } from './bookings.service';
import {
  EstimateDto,
  CreateBookingDto,
  CancelBookingDto,
  ReviewBookingDto,
  BookingQueryDto,
} from './dto/bookings.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Bookings')
@Controller('bookings')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class BookingsController {
  constructor(private bookingsService: BookingsService) {}

  @Post('estimate')
  @ApiOperation({ summary: 'Estimate booking price' })
  async estimateBooking(@Body() dto: EstimateDto) {
    return this.bookingsService.estimateBooking(dto);
  }

  @Post()
  @ApiOperation({ summary: 'Create new booking' })
  async createBooking(@CurrentUser() user: any, @Body() dto: CreateBookingDto) {
    return this.bookingsService.createBooking(BigInt(user.userId), dto);
  }

  @Get()
  @ApiOperation({ summary: 'List my bookings' })
  async getBookings(@CurrentUser() user: any, @Query() query: BookingQueryDto) {
    return this.bookingsService.getBookings(BigInt(user.userId), query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get booking details' })
  @ApiParam({ name: 'id', example: 1 })
  async getBookingById(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.bookingsService.getBookingById(BigInt(user.userId), BigInt(id));
  }

  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Cancel booking (Customer)' })
  @ApiParam({ name: 'id', example: 1 })
  async cancelBooking(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: CancelBookingDto,
  ) {
    return this.bookingsService.cancelBooking(BigInt(user.userId), BigInt(id), dto);
  }

  @Post(':id/review')
  @ApiOperation({ summary: 'Review booking (Customer)' })
  @ApiParam({ name: 'id', example: 1 })
  async reviewBooking(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ReviewBookingDto,
  ) {
    return this.bookingsService.reviewBooking(BigInt(user.userId), BigInt(id), dto);
  }
}

@ApiTags('Provider Bookings')
@Controller('provider/bookings')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('provider')
@ApiBearerAuth()
export class ProviderBookingsController {
  constructor(private bookingsService: BookingsService) {}

  @Patch(':id/accept')
  @ApiOperation({ summary: 'Accept booking (Provider)' })
  @ApiParam({ name: 'id', example: 1 })
  async acceptBooking(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.bookingsService.acceptBooking(BigInt(user.userId), BigInt(id));
  }

  @Patch(':id/start')
  @ApiOperation({ summary: 'Start service (Provider)' })
  @ApiParam({ name: 'id', example: 1 })
  async startBooking(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.bookingsService.startBooking(BigInt(user.userId), BigInt(id));
  }

  @Patch(':id/complete')
  @ApiOperation({ summary: 'Complete service (Provider)' })
  @ApiParam({ name: 'id', example: 1 })
  async completeBooking(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.bookingsService.completeBooking(BigInt(user.userId), BigInt(id));
  }
}
