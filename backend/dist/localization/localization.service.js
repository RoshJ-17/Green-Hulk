"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var LocalizationService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.LocalizationService = void 0;
const common_1 = require("@nestjs/common");
const fs = __importStar(require("fs/promises"));
const path = __importStar(require("path"));
let LocalizationService = LocalizationService_1 = class LocalizationService {
    constructor() {
        this.logger = new common_1.Logger(LocalizationService_1.name);
        this.translationsCache = new Map();
        this.translationsPath = path.join(__dirname, "translations");
    }
    async getTranslations(language) {
        this.logger.debug(`Loading translations for language: ${language}`);
        if (this.translationsCache.has(language)) {
            this.logger.debug(`Returning cached translations for ${language}`);
            return this.translationsCache.get(language);
        }
        const filePath = path.join(this.translationsPath, `${language}.json`);
        try {
            const fileContent = await fs.readFile(filePath, "utf-8");
            const translations = JSON.parse(fileContent);
            this.translationsCache.set(language, translations);
            this.logger.log(`Loaded translations for ${language}`);
            return translations;
        }
        catch (error) {
            this.logger.warn(`Failed to load translations for ${language}: ${error.message}`);
            if (language !== "en") {
                this.logger.debug("Falling back to English translations");
                return this.getTranslations("en");
            }
            throw new common_1.NotFoundException(`Translations for language "${language}" not found`);
        }
    }
    detectLanguage(acceptLanguageHeader) {
        this.logger.debug(`Detecting language from header: ${acceptLanguageHeader}`);
        if (!acceptLanguageHeader) {
            return "en";
        }
        const languages = acceptLanguageHeader
            .split(",")
            .map((lang) => {
            const parts = lang.trim().split(";");
            const code = parts[0].split("-")[0];
            const quality = parts[1] ? parseFloat(parts[1].split("=")[1]) : 1.0;
            return { code, quality };
        })
            .sort((a, b) => b.quality - a.quality);
        const supportedLanguages = ["en", "ta"];
        for (const lang of languages) {
            if (supportedLanguages.includes(lang.code)) {
                this.logger.debug(`Detected language: ${lang.code}`);
                return lang.code;
            }
        }
        this.logger.debug("No supported language found, defaulting to English");
        return "en";
    }
    async getSupportedLanguages() {
        try {
            const files = await fs.readdir(this.translationsPath);
            const languages = files
                .filter((file) => file.endsWith(".json"))
                .map((file) => file.replace(".json", ""));
            this.logger.debug(`Supported languages: ${languages.join(", ")}`);
            return languages;
        }
        catch (error) {
            this.logger.error(`Error reading translations directory: ${error.message}`);
            return ["en"];
        }
    }
    async getTranslation(language, key) {
        const translations = await this.getTranslations(language);
        const keys = key.split(".");
        let value = translations;
        for (const k of keys) {
            if (value && typeof value === "object" && k in value) {
                value = value[k];
            }
            else {
                this.logger.warn(`Translation key "${key}" not found for language "${language}"`);
                return key;
            }
        }
        return value;
    }
    clearCache() {
        this.translationsCache.clear();
        this.logger.log("Translations cache cleared");
    }
    async reloadLanguage(language) {
        this.translationsCache.delete(language);
        await this.getTranslations(language);
        this.logger.log(`Reloaded translations for ${language}`);
    }
    async getLanguageInfo(language) {
        const languageInfo = {
            en: {
                code: "en",
                name: "English",
                nativeName: "English",
            },
            ta: {
                code: "ta",
                name: "Tamil",
                nativeName: "தமிழ்",
            },
        };
        return languageInfo[language] || languageInfo.en;
    }
};
exports.LocalizationService = LocalizationService;
exports.LocalizationService = LocalizationService = LocalizationService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [])
], LocalizationService);
//# sourceMappingURL=localization.service.js.map