import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    Query,
    ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { UserPreferencesService } from '@database/services/user-preferences.service';
import { ScanHistoryService } from '@database/services/scan-history.service';
import { StorageUtilityService } from '@database/services/storage-utility.service';

/**
 * Preferences Controller
 * Task 1.1.4: Crop memory API endpoints
 */
@ApiTags('Preferences')
@Controller('api/preferences')
export class PreferencesController {
    constructor(
        private readonly preferencesService: UserPreferencesService,
        private readonly storageService: StorageUtilityService,
    ) { }

    /**
     * Get user preferences
     */
    @Get(':userId')
    @ApiOperation({ summary: 'Get user preferences' })
    async getUserPreferences(@Param('userId', ParseIntPipe) userId: number) {
        return this.preferencesService.getUserPreferences(userId);
    }

    /**
     * Save user's selected crop
     * Task 1.1.4: Save crop selection endpoint
     */
    @Post(':userId/crop')
    @ApiOperation({ summary: 'Save last selected crop' })
    @ApiResponse({ status: 200, description: 'Crop saved successfully' })
    async saveLastCrop(
        @Param('userId', ParseIntPipe) userId: number,
        @Body('cropId') cropId: string,
    ) {
        return this.preferencesService.saveLastCrop(userId, cropId);
    }

    /**
     * Get user's last selected crop for auto-selection
     * Task 1.1.4: Retrieve last crop on initialization
     */
    @Get(':userId/crop/last')
    @ApiOperation({ summary: 'Get last selected crop' })
    @ApiResponse({ status: 200, description: 'Returns last selected crop' })
    async getLastCrop(@Param('userId', ParseIntPipe) userId: number) {
        const cropId = await this.preferencesService.getLastCrop(userId);
        return { cropId };
    }

    /**
     * Save language preference
     * Task 1.2.3: Language selection persistence
     */
    @Post(':userId/language')
    @ApiOperation({ summary: 'Save preferred language' })
    async saveLanguage(
        @Param('userId', ParseIntPipe) userId: number,
        @Body('language') language: string,
    ) {
        return this.preferencesService.saveLanguage(userId, language);
    }

    /**
     * Set organic preference
     * Task 3.2.1: Organic filter preference
     */
    @Post(':userId/organic')
    @ApiOperation({ summary: 'Set organic treatment preference' })
    async setOrganicPreference(
        @Param('userId', ParseIntPipe) userId: number,
        @Body('preferOrganic') preferOrganic: boolean,
    ) {
        return this.preferencesService.setOrganicPreference(userId, preferOrganic);
    }

    /**
     * Get storage information
     * Task 4.4.4: Storage check endpoint
     */
    @Get('storage/info')
    @ApiOperation({ summary: 'Get storage information' })
    @ApiResponse({ status: 200, description: 'Returns storage statistics' })
    async getStorageInfo() {
        return this.storageService.getStorageInfo();
    }
}
