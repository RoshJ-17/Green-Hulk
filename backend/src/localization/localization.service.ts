import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import * as fs from 'fs/promises';
import * as path from 'path';

/**
 * Localization Service
 * Tasks 1.2.1 & 1.2.3: Translation JSON management and language detection
 */
@Injectable()
export class LocalizationService {
    private readonly logger = new Logger(LocalizationService.name);
    private readonly translationsPath: string;
    private translationsCache: Map<string, any> = new Map();

    constructor() {
        this.translationsPath = path.join(__dirname, 'translations');
    }

    /**
     * Get translations for a specific language
     * Task 1.2.1: Load translation JSON file
     */
    async getTranslations(language: string): Promise<any> {
        this.logger.debug(`Loading translations for language: ${language}`);

        // Check cache first
        if (this.translationsCache.has(language)) {
            this.logger.debug(`Returning cached translations for ${language}`);
            return this.translationsCache.get(language);
        }

        // Load from file
        const filePath = path.join(this.translationsPath, `${language}.json`);

        try {
            const fileContent = await fs.readFile(filePath, 'utf-8');
            const translations = JSON.parse(fileContent);

            // Cache the translations
            this.translationsCache.set(language, translations);

            this.logger.log(`Loaded translations for ${language}`);
            return translations;
        } catch (error) {
            this.logger.warn(`Failed to load translations for ${language}: ${error.message}`);

            // Fallback to English if language not found
            if (language !== 'en') {
                this.logger.debug('Falling back to English translations');
                return this.getTranslations('en');
            }

            throw new NotFoundException(`Translations for language "${language}" not found`);
        }
    }

    /**
     * Detect user's preferred language from Accept-Language header
     * Task 1.2.3: System language detection and mapping logic
     */
    detectLanguage(acceptLanguageHeader?: string): string {
        this.logger.debug(`Detecting language from header: ${acceptLanguageHeader}`);

        if (!acceptLanguageHeader) {
            return 'en'; // Default to English
        }

        // Parse Accept-Language header (e.g., "en-US,en;q=0.9,ta;q=0.8")
        const languages = acceptLanguageHeader
            .split(',')
            .map((lang) => {
                const parts = lang.trim().split(';');
                const code = parts[0].split('-')[0]; // Get language code without region
                const quality = parts[1] ? parseFloat(parts[1].split('=')[1]) : 1.0;
                return { code, quality };
            })
            .sort((a, b) => b.quality - a.quality);

        // Check for supported languages
        const supportedLanguages = ['en', 'ta'];

        for (const lang of languages) {
            if (supportedLanguages.includes(lang.code)) {
                this.logger.debug(`Detected language: ${lang.code}`);
                return lang.code;
            }
        }

        // Default to English
        this.logger.debug('No supported language found, defaulting to English');
        return 'en';
    }

    /**
     * Get supported languages
     */
    async getSupportedLanguages(): Promise<string[]> {
        try {
            const files = await fs.readdir(this.translationsPath);
            const languages = files
                .filter((file) => file.endsWith('.json'))
                .map((file) => file.replace('.json', ''));

            this.logger.debug(`Supported languages: ${languages.join(', ')}`);
            return languages;
        } catch (error) {
            this.logger.error(`Error reading translations directory: ${error.message}`);
            return ['en']; // Fallback to English only
        }
    }

    /**
     * Get specific translation key
     */
    async getTranslation(language: string, key: string): Promise<string> {
        const translations = await this.getTranslations(language);

        // Support nested keys like "home.title"
        const keys = key.split('.');
        let value = translations;

        for (const k of keys) {
            if (value && typeof value === 'object' && k in value) {
                value = value[k];
            } else {
                this.logger.warn(`Translation key "${key}" not found for language "${language}"`);
                return key; // Return the key itself if translation not found
            }
        }

        return value as string;
    }

    /**
     * Clear translations cache
     */
    clearCache(): void {
        this.translationsCache.clear();
        this.logger.log('Translations cache cleared');
    }

    /**
     * Reload translations for a specific language
     */
    async reloadLanguage(language: string): Promise<void> {
        this.translationsCache.delete(language);
        await this.getTranslations(language);
        this.logger.log(`Reloaded translations for ${language}`);
    }

    /**
     * Get language metadata
     */
    async getLanguageInfo(language: string): Promise<{
        code: string;
        name: string;
        nativeName: string;
    }> {
        const languageInfo: Record<string, { code: string; name: string; nativeName: string }> = {
            en: {
                code: 'en',
                name: 'English',
                nativeName: 'English',
            },
            ta: {
                code: 'ta',
                name: 'Tamil',
                nativeName: 'தமிழ்',
            },
        };

        return languageInfo[language] || languageInfo.en;
    }
}
