import { Controller, Get, Query, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ScanRecord } from '@database/entities/scan-record.entity';

@ApiTags('history')
@Controller('api/history')
export class HistoryController {
    constructor(
        @InjectRepository(ScanRecord)
        private readonly scanRepository: Repository<ScanRecord>,
    ) { }

    @Get()
    @ApiOperation({ summary: 'Get scan history for a user' })
    @ApiQuery({ name: 'userId', required: true, type: String })
    @ApiResponse({ status: 200, description: 'List of scan records' })
    async getHistory(@Query('userId') userId: string) {
        return this.scanRepository.find({
            where: { userId },
            order: { timestamp: 'DESC' },
        });
    }
}
