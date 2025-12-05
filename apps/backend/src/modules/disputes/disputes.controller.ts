import { Body, Controller, Post, Get, UseGuards, Query } from '@nestjs/common';
import {
    ApiBearerAuth,
    ApiOperation,
    ApiResponse,
    ApiTags,
} from '@nestjs/swagger';
import { DisputesService } from './disputes.service';
import { CreateDisputeDto, GetDisputesDto } from './dto/dispute.dto';
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

    @Post()
    @ApiOperation({ summary: 'Create dispute' })
    @ApiResponse({ status: 201, description: 'Dispute created' })
    async create(@CurrentUser() user: JwtPayload, @Body() dto: CreateDisputeDto) {
        return this.disputesService.createDispute(BigInt(user.userId), dto);
    }
}
