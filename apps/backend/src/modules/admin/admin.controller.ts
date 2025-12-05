import { Body, Controller, Param, Post, UseGuards, Get, Query, Patch } from '@nestjs/common';
import {
    ApiBearerAuth,
    ApiOperation,
    ApiResponse,
    ApiTags,
} from '@nestjs/swagger';
import { AdminService } from './admin.service';
import {
    ResolveDisputeDto,
    AdminDashboardQueryDto,
    AdminDisputesQueryDto,
    AdminWithdrawalsQueryDto,
    ApproveWithdrawalDto,
    RejectWithdrawalDto,
    AdminUsersQueryDto,
    AdminProvidersQueryDto,
    BanUserDto,
    VerifyProviderDto,
    AdminBookingsQueryDto,
    AdminPaymentsQueryDto,
} from './dto/admin.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../../common/interfaces/jwt-payload.interface';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('admin')
export class AdminController {
    constructor(private adminService: AdminService) { }

    /**
     * Get admin dashboard with overview statistics
     */
    @Get('dashboard')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Get admin dashboard overview' })
    @ApiResponse({ status: 200, description: 'Dashboard data retrieved successfully' })
    async getDashboard(@Query() query: AdminDashboardQueryDto) {
        return this.adminService.getDashboard(query);
    }

    /**
     * Get list of disputes from admin perspective
     */
    @Get('disputes')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Get all disputes (admin view)' })
    @ApiResponse({ status: 200, description: 'Disputes list retrieved successfully' })
    async getDisputes(@Query() query: AdminDisputesQueryDto) {
        return this.adminService.getDisputesForAdmin(query);
    }

    /**
     * Get list of withdrawal requests
     */
    @Get('withdrawals')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Get withdrawal requests' })
    @ApiResponse({ status: 200, description: 'Withdrawals list retrieved successfully' })
    async getWithdrawals(@Query() query: AdminWithdrawalsQueryDto) {
        return this.adminService.getWithdrawalsForAdmin(query);
    }

    /**
     * Approve withdrawal request
     */
    @Patch('withdrawals/:id/approve')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Approve withdrawal request' })
    @ApiResponse({ status: 200, description: 'Withdrawal approved successfully' })
    @ApiResponse({ status: 400, description: 'Invalid withdrawal request' })
    @ApiResponse({ status: 404, description: 'Withdrawal not found' })
    async approveWithdrawal(
        @CurrentUser() user: JwtPayload,
        @Param('id') transactionId: string,
        @Body() dto: ApproveWithdrawalDto
    ) {
        return this.adminService.approveWithdrawal(BigInt(transactionId), BigInt(user.userId), dto);
    }

    /**
     * Reject withdrawal request
     */
    @Patch('withdrawals/:id/reject')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Reject withdrawal request' })
    @ApiResponse({ status: 200, description: 'Withdrawal rejected successfully' })
    @ApiResponse({ status: 400, description: 'Invalid withdrawal request' })
    @ApiResponse({ status: 404, description: 'Withdrawal not found' })
    async rejectWithdrawal(
        @CurrentUser() user: JwtPayload,
        @Param('id') transactionId: string,
        @Body() dto: RejectWithdrawalDto
    ) {
        return this.adminService.rejectWithdrawal(BigInt(transactionId), BigInt(user.userId), dto);
    }

    /**
     * Resolve dispute (existing endpoint - unchanged)
     */
    @Post('disputes/:id/resolve')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Resolve dispute' })
    @ApiResponse({ status: 200, description: 'Dispute resolved' })
    async resolveDispute(
        @CurrentUser() user: JwtPayload,
        @Param('id') id: string,
        @Body() dto: ResolveDisputeDto,
    ) {
        return this.adminService.resolveDispute(
            BigInt(id),
            BigInt(user.userId),
            dto,
        );
    }

    /**
     * Get list of all users
     */
    @Get('users')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Get all users (admin view)' })
    @ApiResponse({ status: 200, description: 'Users list retrieved successfully' })
    async getUsers(@Query() query: AdminUsersQueryDto) {
        return this.adminService.getUsers(query);
    }

    /**
     * Get list of all providers
     */
    @Get('providers')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Get all providers (admin view)' })
    @ApiResponse({ status: 200, description: 'Providers list retrieved successfully' })
    async getProviders(@Query() query: AdminProvidersQueryDto) {
        return this.adminService.getProviders(query);
    }

    /**
     * Ban or unban a user
     */
    @Patch('users/:id/ban')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Ban or unban user' })
    @ApiResponse({ status: 200, description: 'User banned/unbanned successfully' })
    @ApiResponse({ status: 400, description: 'Invalid action or user status' })
    @ApiResponse({ status: 404, description: 'User not found' })
    async banUser(
        @CurrentUser() user: JwtPayload,
        @Param('id') userId: string,
        @Body() dto: BanUserDto
    ) {
        return this.adminService.banUser(BigInt(userId), BigInt(user.userId), dto);
    }

    /**
     * Verify or reject provider
     */
    @Patch('providers/:id/verify')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Verify or reject provider' })
    @ApiResponse({ status: 200, description: 'Provider status updated successfully' })
    @ApiResponse({ status: 400, description: 'Invalid action or missing fields' })
    @ApiResponse({ status: 404, description: 'Provider not found' })
    async verifyProvider(
        @CurrentUser() user: JwtPayload,
        @Param('id') userId: string,
        @Body() dto: VerifyProviderDto
    ) {
        return this.adminService.verifyProvider(BigInt(userId), BigInt(user.userId), dto);
    }

    /**
     * Get list of all bookings
     */
    @Get('bookings')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Get all bookings (admin view)' })
    @ApiResponse({ status: 200, description: 'Bookings list retrieved successfully' })
    async getBookings(@Query() query: AdminBookingsQueryDto) {
        return this.adminService.getBookings(query);
    }

    /**
     * Get single booking detail
     */
    @Get('bookings/:id')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Get booking detail (admin view)' })
    @ApiResponse({ status: 200, description: 'Booking detail retrieved successfully' })
    @ApiResponse({ status: 404, description: 'Booking not found' })
    async getBookingDetail(@Param('id') bookingId: string) {
        return this.adminService.getBookingDetail(BigInt(bookingId));
    }

    /**
     * Get list of all payments
     */
    @Get('payments')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Get all payments (admin view)' })
    @ApiResponse({ status: 200, description: 'Payments list retrieved successfully' })
    async getPayments(@Query() query: AdminPaymentsQueryDto) {
        return this.adminService.getPayments(query);
    }

    /**
     * Get user wallet details
     */
    @Get('wallets/:userId')
    @Roles('admin', 'super_admin')
    @ApiOperation({ summary: 'Get user wallet details' })
    @ApiResponse({ status: 200, description: 'Wallet details retrieved successfully' })
    @ApiResponse({ status: 404, description: 'Wallet not found' })
    async getWallet(
        @Param('userId') userId: string,
        @Query('page') page?: string,
        @Query('limit') limit?: string
    ) {
        const pageNum = page ? parseInt(page, 10) : 1;
        const limitNum = limit ? parseInt(limit, 10) : 20;
        return this.adminService.getWallet(BigInt(userId), pageNum, limitNum);
    }
}
