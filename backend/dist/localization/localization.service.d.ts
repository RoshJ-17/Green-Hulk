export declare class LocalizationService {
    private readonly logger;
    private readonly translationsPath;
    private translationsCache;
    constructor();
    getTranslations(language: string): Promise<any>;
    detectLanguage(acceptLanguageHeader?: string): string;
    getSupportedLanguages(): Promise<string[]>;
    getTranslation(language: string, key: string): Promise<string>;
    clearCache(): void;
    reloadLanguage(language: string): Promise<void>;
    getLanguageInfo(language: string): Promise<{
        code: string;
        name: string;
        nativeName: string;
    }>;
}
