import {
    Controller,
    Get,
    Delete,
    Param,
    Query,
    NotFoundException,
    ParseIntPipe,
    Logger,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ScanRecord } from '@database/entities/scan-record.entity';

@ApiTags('scans')
@Controller('api/scans')
export class ScansController {
    private readonly logger = new Logger(ScansController.name);

    constructor(
        @InjectRepository(ScanRecord)
        private readonly scanRepository: Repository<ScanRecord>,
    ) { }

    @Get()
    @ApiOperation({ summary: 'Get scan history' })
    @ApiQuery({ name: 'page', required: false, type: Number })
    @ApiQuery({ name: 'limit', required: false, type: Number })
    @ApiQuery({ name: 'cropType', required: false, type: String })
    @ApiResponse({ status: 200, description: 'Paginated scan history' })
    async getScans(
        @Query('page') page: number = 1,
        @Query('limit') limit: number = 20,
        @Query('cropType') cropType?: string,
    ) {
        const skip = (page - 1) * limit;

        const queryBuilder = this.scanRepository
            .createQueryBuilder('scan')
            .orderBy('scan.timestamp', 'DESC')
            .skip(skip)
            .take(limit);

        if (cropType) {
            queryBuilder.where('scan.cropType = :cropType', { cropType });
        }

        const [scans, total] = await queryBuilder.getManyAndCount();

        return {
            data: scans,
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit),
            },
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get specific scan by ID' })
    @ApiResponse({ status: 200, description: 'Scan record details' })
    @ApiResponse({ status: 404, description: 'Scan not found' })
    async getScanById(@Param('id', ParseIntPipe) id: number) {
        const scan = await this.scanRepository.findOne({ where: { id } });

        if (!scan) {
            throw new NotFoundException(`Scan with ID ${id} not found`);
        }

        return scan;
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete scan record' })
    @ApiResponse({ status: 200, description: 'Scan deleted successfully' })
    @ApiResponse({ status: 404, description: 'Scan not found' })
    async deleteScan(@Param('id', ParseIntPipe) id: number) {
        const result = await this.scanRepository.delete(id);

        if (result.affected === 0) {
            throw new NotFoundException(`Scan with ID ${id} not found`);
        }

        this.logger.log(`Scan record deleted: ID ${id}`);

        return {
            message: 'Scan deleted successfully',
            id,
        };
    }

    @Get('unsynced/list')
    @ApiOperation({ summary: 'Get unsynced scan records' })
    @ApiResponse({ status: 200, description: 'List of unsynced scans' })
    async getUnsyncedScans() {
        const scans = await this.scanRepository.find({
            where: { isSynced: false },
            order: { timestamp: 'DESC' },
        });

        return {
            data: scans,
            count: scans.length,
        };
    }
}
