import { Body, Controller, Param, Post, UseGuards } from '@nestjs/common';
import {
    ApiBearerAuth,
    ApiOperation,
    ApiResponse,
    ApiTags,
} from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { ResolveDisputeDto } from './dto/admin.dto';
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
