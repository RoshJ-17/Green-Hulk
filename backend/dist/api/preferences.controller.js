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
exports.PreferencesController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const user_preferences_service_1 = require("../database/services/user-preferences.service");
const storage_utility_service_1 = require("../database/services/storage-utility.service");
let PreferencesController = class PreferencesController {
    constructor(preferencesService, storageService) {
        this.preferencesService = preferencesService;
        this.storageService = storageService;
    }
    async getUserPreferences(userId) {
        return this.preferencesService.getUserPreferences(userId);
    }
    async saveLastCrop(userId, cropId) {
        return this.preferencesService.saveLastCrop(userId, cropId);
    }
    async getLastCrop(userId) {
        const cropId = await this.preferencesService.getLastCrop(userId);
        return { cropId };
    }
    async saveLanguage(userId, language) {
        return this.preferencesService.saveLanguage(userId, language);
    }
    async setOrganicPreference(userId, preferOrganic) {
        return this.preferencesService.setOrganicPreference(userId, preferOrganic);
    }
    async getStorageInfo() {
        return this.storageService.getStorageInfo();
    }
};
exports.PreferencesController = PreferencesController;
__decorate([
    (0, common_1.Get)(':userId'),
    (0, swagger_1.ApiOperation)({ summary: 'Get user preferences' }),
    __param(0, (0, common_1.Param)('userId', common_1.ParseIntPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", Promise)
], PreferencesController.prototype, "getUserPreferences", null);
__decorate([
    (0, common_1.Post)(':userId/crop'),
    (0, swagger_1.ApiOperation)({ summary: 'Save last selected crop' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Crop saved successfully' }),
    __param(0, (0, common_1.Param)('userId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Body)('cropId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, String]),
    __metadata("design:returntype", Promise)
], PreferencesController.prototype, "saveLastCrop", null);
__decorate([
    (0, common_1.Get)(':userId/crop/last'),
    (0, swagger_1.ApiOperation)({ summary: 'Get last selected crop' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Returns last selected crop' }),
    __param(0, (0, common_1.Param)('userId', common_1.ParseIntPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", Promise)
], PreferencesController.prototype, "getLastCrop", null);
__decorate([
    (0, common_1.Post)(':userId/language'),
    (0, swagger_1.ApiOperation)({ summary: 'Save preferred language' }),
    __param(0, (0, common_1.Param)('userId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Body)('language')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, String]),
    __metadata("design:returntype", Promise)
], PreferencesController.prototype, "saveLanguage", null);
__decorate([
    (0, common_1.Post)(':userId/organic'),
    (0, swagger_1.ApiOperation)({ summary: 'Set organic treatment preference' }),
    __param(0, (0, common_1.Param)('userId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Body)('preferOrganic')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Boolean]),
    __metadata("design:returntype", Promise)
], PreferencesController.prototype, "setOrganicPreference", null);
__decorate([
    (0, common_1.Get)('storage/info'),
    (0, swagger_1.ApiOperation)({ summary: 'Get storage information' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Returns storage statistics' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], PreferencesController.prototype, "getStorageInfo", null);
exports.PreferencesController = PreferencesController = __decorate([
    (0, swagger_1.ApiTags)('Preferences'),
    (0, common_1.Controller)('api/preferences'),
    __metadata("design:paramtypes", [user_preferences_service_1.UserPreferencesService,
        storage_utility_service_1.StorageUtilityService])
], PreferencesController);
//# sourceMappingURL=preferences.controller.js.map