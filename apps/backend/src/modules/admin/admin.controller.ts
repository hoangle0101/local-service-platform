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
}
