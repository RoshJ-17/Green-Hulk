"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DatabaseModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const config_1 = require("@nestjs/config");
const scan_record_entity_1 = require("./entities/scan-record.entity");
const treatment_plan_entity_1 = require("./entities/treatment-plan.entity");
const user_preferences_entity_1 = require("./entities/user-preferences.entity");
const user_preferences_service_1 = require("./services/user-preferences.service");
const scan_history_service_1 = require("./services/scan-history.service");
const storage_utility_service_1 = require("./services/storage-utility.service");
const user_entity_1 = require("./entities/user.entity");
let DatabaseModule = class DatabaseModule {
};
exports.DatabaseModule = DatabaseModule;
exports.DatabaseModule = DatabaseModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forRootAsync({
                imports: [config_1.ConfigModule],
                useFactory: (configService) => ({
                    type: "sqlite",
                    database: configService.get("DB_PATH") || "./data/plant-disease.db",
                    entities: [scan_record_entity_1.ScanRecord, treatment_plan_entity_1.TreatmentPlan, user_preferences_entity_1.UserPreferences, user_entity_1.User],
                    synchronize: true,
                    logging: configService.get("NODE_ENV") === "development",
                }),
                inject: [config_1.ConfigService],
            }),
            typeorm_1.TypeOrmModule.forFeature([
                scan_record_entity_1.ScanRecord,
                treatment_plan_entity_1.TreatmentPlan,
                user_preferences_entity_1.UserPreferences,
                user_entity_1.User,
            ]),
        ],
        providers: [
            user_preferences_service_1.UserPreferencesService,
            scan_history_service_1.ScanHistoryService,
            storage_utility_service_1.StorageUtilityService,
        ],
        exports: [
            typeorm_1.TypeOrmModule,
            user_preferences_service_1.UserPreferencesService,
            scan_history_service_1.ScanHistoryService,
            storage_utility_service_1.StorageUtilityService,
        ],
    })
], DatabaseModule);
//# sourceMappingURL=database.module.js.map