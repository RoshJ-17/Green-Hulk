"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const api_module_1 = require("./api/api.module");
const database_module_1 = require("./database/database.module");
const diagnosis_module_1 = require("./diagnosis/diagnosis.module");
const ml_module_1 = require("./ml/ml.module");
const image_module_1 = require("./image/image.module");
const validators_module_1 = require("./validators/validators.module");
const localization_module_1 = require("./localization/localization.module");
const treatments_module_1 = require("./treatments/treatments.module");
const auth_module_1 = require("./auth/auth.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({
                isGlobal: true,
                envFilePath: ".env",
            }),
            database_module_1.DatabaseModule,
            auth_module_1.AuthModule,
            ml_module_1.MlModule,
            image_module_1.ImageModule,
            validators_module_1.ValidatorsModule,
            diagnosis_module_1.DiagnosisModule,
            localization_module_1.LocalizationModule,
            treatments_module_1.TreatmentsModule,
            api_module_1.ApiModule,
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map