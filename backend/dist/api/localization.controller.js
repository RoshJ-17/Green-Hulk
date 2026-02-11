"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.LocalizationController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const localization_service_1 = require("../localization/localization.service");
let LocalizationController = class LocalizationController {
    constructor(localizationService) {
        this.localizationService = localizationService;
    }
    async getTranslations(language) {
        return this.localizationService.getTranslations(language);
    }
    async detectLanguage(acceptLanguage) {
        const language = this.localizationService.detectLanguage(acceptLanguage);
        const translations = await this.localizationService.getTranslations(language);
        return {
            detectedLanguage: language,
            translations,
        };
    }
    async getSupportedLanguages() {
        const languages = await this.localizationService.getSupportedLanguages();
        const languageInfo = await Promise.all(languages.map((lang) => this.localizationService.getLanguageInfo(lang)));
        return {
            languages: languageInfo,
        };
    }
    async getTranslationKey(language, key) {
        const value = await this.localizationService.getTranslation(language, key);
        return { key, value };
    }
};
exports.LocalizationController = LocalizationController;
__decorate([
    (0, common_1.Get)(':language'),
    (0, swagger_1.ApiOperation)({ summary: 'Get translations for a language' }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Returns translation JSON for the specified language',
    }),
    __param(0, (0, common_1.Param)('language')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], LocalizationController.prototype, "getTranslations", null);
__decorate([
    (0, common_1.Get)('detect/auto'),
    (0, swagger_1.ApiOperation)({ summary: 'Detect preferred language from headers' }),
    (0, swagger_1.ApiHeader)({
        name: 'Accept-Language',
        description: 'Browser Accept-Language header',
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Returns detected language code',
    }),
    __param(0, (0, common_1.Headers)('accept-language')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], LocalizationController.prototype, "detectLanguage", null);
__decorate([
    (0, common_1.Get)('languages/supported'),
    (0, swagger_1.ApiOperation)({ summary: 'Get list of supported languages' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], LocalizationController.prototype, "getSupportedLanguages", null);
__decorate([
    (0, common_1.Get)(':language/key/:key'),
    (0, swagger_1.ApiOperation)({ summary: 'Get specific translation key' }),
    __param(0, (0, common_1.Param)('language')),
    __param(1, (0, common_1.Param)('key')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], LocalizationController.prototype, "getTranslationKey", null);
exports.LocalizationController = LocalizationController = __decorate([
    (0, swagger_1.ApiTags)('Localization'),
    (0, common_1.Controller)('api/i18n'),
    __metadata("design:paramtypes", [localization_service_1.LocalizationService])
], LocalizationController);
//# sourceMappingURL=localization.controller.js.map