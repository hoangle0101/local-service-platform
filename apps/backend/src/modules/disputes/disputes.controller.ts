import { Body, Controller, Post, Get, UseGuards, Query, Param, Patch } from '@nestjs/common';
import {
    ApiBearerAuth,
    ApiOperation,
    ApiResponse,
    ApiTags,
} from '@nestjs/swagger';
import { DisputesService } from './disputes.service';
import { CreateDisputeDto, GetDisputesDto, GetDisputeDetailDto, UpdateDisputeAppealDto } from './dto/dispute.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../../common/interfaces/jwt-payload.interface';

@ApiTags('Disputes')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('disputes')
export class DisputesController {
    constructor(private disputesService: DisputesService) { }

    @Get()
    @ApiOperation({ summary: 'Get list of disputes' })
    @ApiResponse({ status: 200, description: 'Disputes list retrieved successfully' })
    async findAll(@CurrentUser() user: JwtPayload, @Query() query: GetDisputesDto) {
        return this.disputesService.getDisputesList(BigInt(user.userId), query);
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get detail of a single dispute' })
    @ApiResponse({ status: 200, description: 'Dispute detail retrieved successfully' })
    @ApiResponse({ status: 404, description: 'Dispute not found' })
    async findOne(
        @CurrentUser() user: JwtPayload,
        @Param('id') disputeId: string,
        @Query() query: GetDisputeDetailDto
    ) {
        return this.disputesService.getDisputeDetail(BigInt(user.userId), BigInt(disputeId), query);
    }

    @Post()
    @ApiOperation({ summary: 'Create dispute' })
    @ApiResponse({ status: 201, description: 'Dispute created' })
    async create(@CurrentUser() user: JwtPayload, @Body() dto: CreateDisputeDto) {
        return this.disputesService.createDispute(BigInt(user.userId), dto);
    }

    @Patch(':id/appeal')
    @ApiOperation({ summary: 'Appeal a dispute decision' })
    @ApiResponse({ status: 200, description: 'Dispute appealed successfully' })
    @ApiResponse({ status: 400, description: 'Cannot appeal this dispute' })
    @ApiResponse({ status: 404, description: 'Dispute not found' })
    async appealDispute(
        @CurrentUser() user: JwtPayload,
        @Param('id') disputeId: string,
        @Body() dto: UpdateDisputeAppealDto
    ) {
        return this.disputesService.appealDispute(BigInt(user.userId), BigInt(disputeId), dto);
    }
}
