import { Controller, Get, Param, Headers } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiHeader } from '@nestjs/swagger';
import { LocalizationService } from '@localization/localization.service';

/**
 * Localization Controller
 * Tasks 1.2.1 & 1.2.3: Translation and language detection endpoints
 */
@ApiTags('Localization')
@Controller('api/i18n')
export class LocalizationController {
    constructor(private readonly localizationService: LocalizationService) { }

    /**
     * Get translations for a specific language
     * Task 1.2.1: Serve translation JSON
     */
    @Get(':language')
    @ApiOperation({ summary: 'Get translations for a language' })
    @ApiResponse({
        status: 200,
        description: 'Returns translation JSON for the specified language',
    })
    async getTranslations(@Param('language') language: string) {
        return this.localizationService.getTranslations(language);
    }

    /**
     * Detect language from Accept-Language header
     * Task 1.2.3: Automatic language detection
     */
    @Get('detect/auto')
    @ApiOperation({ summary: 'Detect preferred language from headers' })
    @ApiHeader({
        name: 'Accept-Language',
        description: 'Browser Accept-Language header',
    })
    @ApiResponse({
        status: 200,
        description: 'Returns detected language code',
    })
    async detectLanguage(@Headers('accept-language') acceptLanguage?: string) {
        const language = this.localizationService.detectLanguage(acceptLanguage);
        const translations = await this.localizationService.getTranslations(language);

        return {
            detectedLanguage: language,
            translations,
        };
    }

    /**
     * Get supported languages
     */
    @Get('languages/supported')
    @ApiOperation({ summary: 'Get list of supported languages' })
    async getSupportedLanguages() {
        const languages = await this.localizationService.getSupportedLanguages();
        const languageInfo = await Promise.all(
            languages.map((lang: string) => this.localizationService.getLanguageInfo(lang)),
        );

        return {
            languages: languageInfo,
        };
    }

    /**
     * Get specific translation key
     */
    @Get(':language/key/:key')
    @ApiOperation({ summary: 'Get specific translation key' })
    async getTranslationKey(
        @Param('language') language: string,
        @Param('key') key: string,
    ) {
        const value = await this.localizationService.getTranslation(language, key);
        return { key, value };
    }
}
