import { LocalizationService } from "@localization/localization.service";
export declare class LocalizationController {
    private readonly localizationService;
    constructor(localizationService: LocalizationService);
    getTranslations(language: string): Promise<any>;
    detectLanguage(acceptLanguage?: string): Promise<{
        detectedLanguage: string;
        translations: any;
    }>;
    getSupportedLanguages(): Promise<{
        languages: {
            code: string;
            name: string;
            nativeName: string;
        }[];
    }>;
    getTranslationKey(language: string, key: string): Promise<{
        key: string;
        value: string;
    }>;
}
