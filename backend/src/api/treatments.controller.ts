import { Controller, Get, Param, Query, ParseBoolPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { TreatmentsService } from '@treatments/treatments.service';

/**
 * Treatments Controller
 * Tasks 3.1.1 & 3.2.1: Treatment database and organic filtering endpoints
 */
@ApiTags('Treatments')
@Controller('api/treatments')
export class TreatmentsController {
    constructor(private readonly treatmentsService: TreatmentsService) { }

    /**
     * Get all available diseases
     */
    @Get('diseases')
    @ApiOperation({ summary: 'Get all available diseases' })
    async getAllDiseases() {
        return this.treatmentsService.getAllDiseases();
    }

    /**
     * Get treatments for a specific disease
     * Task 3.1.1: Treatment database retrieval
     */
    @Get(':diseaseKey')
    @ApiOperation({ summary: 'Get treatments for a disease' })
    @ApiQuery({
        name: 'organicOnly',
        required: false,
        type: Boolean,
        description: 'Filter for organic treatments only',
    })
    @ApiResponse({
        status: 200,
        description: 'Returns all treatments for the disease',
    })
    async getTreatments(
        @Param('diseaseKey') diseaseKey: string,
        @Query('organicOnly', new ParseBoolPipe({ optional: true }))
        organicOnly?: boolean,
    ) {
        return this.treatmentsService.getTreatments(diseaseKey, { organicOnly });
    }

    /**
     * Get only organic treatments
     * Task 3.2.1: Organic filter endpoint
     */
    @Get(':diseaseKey/organic')
    @ApiOperation({ summary: 'Get organic treatments only' })
    @ApiResponse({
        status: 200,
        description: 'Returns organic treatments',
    })
    async getOrganicTreatments(@Param('diseaseKey') diseaseKey: string) {
        const treatments = await this.treatmentsService.getOrganicTreatments(diseaseKey);
        return { treatments, count: treatments.length };
    }

    /**
     * Get chemical treatments
     */
    @Get(':diseaseKey/chemical')
    @ApiOperation({ summary: 'Get chemical treatments' })
    async getChemicalTreatments(@Param('diseaseKey') diseaseKey: string) {
        const treatments = await this.treatmentsService.getChemicalTreatments(diseaseKey);
        return { treatments, count: treatments.length };
    }

    /**
     * Get treatment steps with timeframe splitting
     * Task 14593: Divide steps into "today" and "week"
     */
    @Get(':diseaseKey/steps/:treatmentId')
    @ApiOperation({ summary: 'Get treatment steps' })
    @ApiQuery({
        name: 'split',
        required: false,
        type: Boolean,
        description: 'Split steps by timeframe (today/week)',
    })
    async getTreatmentSteps(
        @Param('diseaseKey') diseaseKey: string,
        @Param('treatmentId') treatmentId: string,
        @Query('split', new ParseBoolPipe({ optional: true })) split?: boolean,
    ) {
        return this.treatmentsService.getTreatmentSteps(
            diseaseKey,
            treatmentId,
            split,
        );
    }

    /**
     * Get home remedies for a disease
     * Task 14596: Home remedies endpoint
     */
    @Get(':diseaseKey/home-remedies')
    @ApiOperation({ summary: 'Get home remedies' })
    async getHomeRemedies(@Param('diseaseKey') diseaseKey: string) {
        return this.treatmentsService.getHomeRemedies(diseaseKey);
    }

    /**
     * Get prevention tips
     */
    @Get(':diseaseKey/prevention')
    @ApiOperation({ summary: 'Get prevention guidelines' })
    async getPreventionTips(@Param('diseaseKey') diseaseKey: string) {
        return this.treatmentsService.getPreventionTips(diseaseKey);
    }

    /**
     * Search treatments by crop
     */
    @Get('crop/:cropType')
    @ApiOperation({ summary: 'Get treatments by crop type' })
    async getTreatmentsByCrop(@Param('cropType') crop: string) {
        return this.treatmentsService.getTreatmentsByCrop(crop);
    }
}
