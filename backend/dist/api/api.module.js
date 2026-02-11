"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ApiModule = void 0;
const common_1 = require("@nestjs/common");
const diagnosis_controller_1 = require("./diagnosis.controller");
const scans_controller_1 = require("./scans.controller");
const preferences_controller_1 = require("./preferences.controller");
const localization_controller_1 = require("./localization.controller");
const treatments_controller_1 = require("./treatments.controller");
const diagnosis_module_1 = require("../diagnosis/diagnosis.module");
const database_module_1 = require("../database/database.module");
const localization_module_1 = require("../localization/localization.module");
const treatments_module_1 = require("../treatments/treatments.module");
const validators_module_1 = require("../validators/validators.module");
const ml_module_1 = require("../ml/ml.module");
let ApiModule = class ApiModule {
};
exports.ApiModule = ApiModule;
exports.ApiModule = ApiModule = __decorate([
    (0, common_1.Module)({
        imports: [
            diagnosis_module_1.DiagnosisModule,
            database_module_1.DatabaseModule,
            localization_module_1.LocalizationModule,
            treatments_module_1.TreatmentsModule,
            validators_module_1.ValidatorsModule,
            ml_module_1.MlModule,
        ],
        controllers: [
            diagnosis_controller_1.DiagnosisController,
            scans_controller_1.ScansController,
            preferences_controller_1.PreferencesController,
            localization_controller_1.LocalizationController,
            treatments_controller_1.TreatmentsController,
        ],
    })
], ApiModule);
//# sourceMappingURL=api.module.js.map