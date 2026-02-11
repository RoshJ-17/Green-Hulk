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
var UserPreferencesService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserPreferencesService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const user_preferences_entity_1 = require("../entities/user-preferences.entity");
let UserPreferencesService = UserPreferencesService_1 = class UserPreferencesService {
    constructor(preferencesRepository) {
        this.preferencesRepository = preferencesRepository;
        this.logger = new common_1.Logger(UserPreferencesService_1.name);
    }
    async saveLastCrop(userId, cropId) {
        this.logger.debug(`Saving last crop selection for user ${userId}: ${cropId}`);
        let preferences = await this.preferencesRepository.findOne({
            where: { id: userId },
        });
        if (!preferences) {
            preferences = this.preferencesRepository.create({
                id: userId,
                defaultCrop: cropId,
            });
        }
        else {
            preferences.defaultCrop = cropId;
        }
        const saved = await this.preferencesRepository.save(preferences);
        this.logger.log(`Crop selection saved: ${cropId} for user ${userId}`);
        return saved;
    }
    async getLastCrop(userId) {
        this.logger.debug(`Retrieving last crop for user ${userId}`);
        const preferences = await this.preferencesRepository.findOne({
            where: { id: userId },
        });
        if (!preferences || !preferences.defaultCrop) {
            this.logger.debug(`No saved crop found for user ${userId}`);
            return null;
        }
        this.logger.debug(`Found saved crop: ${preferences.defaultCrop}`);
        return preferences.defaultCrop;
    }
    async getUserPreferences(userId) {
        return this.preferencesRepository.findOne({
            where: { id: userId },
        });
    }
    async updatePreferences(userId, updates) {
        let preferences = await this.preferencesRepository.findOne({
            where: { id: userId },
        });
        if (!preferences) {
            preferences = this.preferencesRepository.create({
                id: userId,
                ...updates,
            });
        }
        else {
            Object.assign(preferences, updates);
        }
        return this.preferencesRepository.save(preferences);
    }
    async saveLanguage(userId, language) {
        this.logger.debug(`Saving language preference for user ${userId}: ${language}`);
        return this.updatePreferences(userId, { preferredLanguage: language });
    }
    async getPreferredLanguage(userId) {
        const preferences = await this.getUserPreferences(userId);
        return preferences?.preferredLanguage || null;
    }
    async setOrganicPreference(userId, preferOrganic) {
        this.logger.debug(`Setting organic preference for user ${userId}: ${preferOrganic}`);
        return this.updatePreferences(userId, {
            preferOrganicTreatments: preferOrganic,
        });
    }
    async getOrganicPreference(userId) {
        const preferences = await this.getUserPreferences(userId);
        return preferences?.preferOrganicTreatments ?? true;
    }
};
exports.UserPreferencesService = UserPreferencesService;
exports.UserPreferencesService = UserPreferencesService = UserPreferencesService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_preferences_entity_1.UserPreferences)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], UserPreferencesService);
//# sourceMappingURL=user-preferences.service.js.map