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
exports.TreatmentsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const treatments_service_1 = require("../treatments/treatments.service");
let TreatmentsController = class TreatmentsController {
    constructor(treatmentsService) {
        this.treatmentsService = treatmentsService;
    }
    async getAllDiseases() {
        return this.treatmentsService.getAllDiseases();
    }
    async getTreatments(diseaseKey, organicOnly) {
        return this.treatmentsService.getTreatments(diseaseKey, { organicOnly });
    }
    async getOrganicTreatments(diseaseKey) {
        const treatments = await this.treatmentsService.getOrganicTreatments(diseaseKey);
        return { treatments, count: treatments.length };
    }
    async getChemicalTreatments(diseaseKey) {
        const treatments = await this.treatmentsService.getChemicalTreatments(diseaseKey);
        return { treatments, count: treatments.length };
    }
    async getTreatmentSteps(diseaseKey, treatmentId, split) {
        return this.treatmentsService.getTreatmentSteps(diseaseKey, treatmentId, split);
    }
    async getHomeRemedies(diseaseKey) {
        return this.treatmentsService.getHomeRemedies(diseaseKey);
    }
    async getPreventionTips(diseaseKey) {
        return this.treatmentsService.getPreventionTips(diseaseKey);
    }
    async getTreatmentsByCrop(crop) {
        return this.treatmentsService.getTreatmentsByCrop(crop);
    }
};
exports.TreatmentsController = TreatmentsController;
__decorate([
    (0, common_1.Get)("diseases"),
    (0, swagger_1.ApiOperation)({ summary: "Get all available diseases" }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], TreatmentsController.prototype, "getAllDiseases", null);
__decorate([
    (0, common_1.Get)(":diseaseKey"),
    (0, swagger_1.ApiOperation)({ summary: "Get treatments for a disease" }),
    (0, swagger_1.ApiQuery)({
        name: "organicOnly",
        required: false,
        type: Boolean,
        description: "Filter for organic treatments only",
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: "Returns all treatments for the disease",
    }),
    __param(0, (0, common_1.Param)("diseaseKey")),
    __param(1, (0, common_1.Query)("organicOnly", new common_1.ParseBoolPipe({ optional: true }))),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Boolean]),
    __metadata("design:returntype", Promise)
], TreatmentsController.prototype, "getTreatments", null);
__decorate([
    (0, common_1.Get)(":diseaseKey/organic"),
    (0, swagger_1.ApiOperation)({ summary: "Get organic treatments only" }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: "Returns organic treatments",
    }),
    __param(0, (0, common_1.Param)("diseaseKey")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], TreatmentsController.prototype, "getOrganicTreatments", null);
__decorate([
    (0, common_1.Get)(":diseaseKey/chemical"),
    (0, swagger_1.ApiOperation)({ summary: "Get chemical treatments" }),
    __param(0, (0, common_1.Param)("diseaseKey")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], TreatmentsController.prototype, "getChemicalTreatments", null);
__decorate([
    (0, common_1.Get)(":diseaseKey/steps/:treatmentId"),
    (0, swagger_1.ApiOperation)({ summary: "Get treatment steps" }),
    (0, swagger_1.ApiQuery)({
        name: "split",
        required: false,
        type: Boolean,
        description: "Split steps by timeframe (today/week)",
    }),
    __param(0, (0, common_1.Param)("diseaseKey")),
    __param(1, (0, common_1.Param)("treatmentId")),
    __param(2, (0, common_1.Query)("split", new common_1.ParseBoolPipe({ optional: true }))),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Boolean]),
    __metadata("design:returntype", Promise)
], TreatmentsController.prototype, "getTreatmentSteps", null);
__decorate([
    (0, common_1.Get)(":diseaseKey/home-remedies"),
    (0, swagger_1.ApiOperation)({ summary: "Get home remedies" }),
    __param(0, (0, common_1.Param)("diseaseKey")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], TreatmentsController.prototype, "getHomeRemedies", null);
__decorate([
    (0, common_1.Get)(":diseaseKey/prevention"),
    (0, swagger_1.ApiOperation)({ summary: "Get prevention guidelines" }),
    __param(0, (0, common_1.Param)("diseaseKey")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], TreatmentsController.prototype, "getPreventionTips", null);
__decorate([
    (0, common_1.Get)("crop/:cropType"),
    (0, swagger_1.ApiOperation)({ summary: "Get treatments by crop type" }),
    __param(0, (0, common_1.Param)("cropType")),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], TreatmentsController.prototype, "getTreatmentsByCrop", null);
exports.TreatmentsController = TreatmentsController = __decorate([
    (0, swagger_1.ApiTags)("Treatments"),
    (0, common_1.Controller)("api/treatments"),
    __metadata("design:paramtypes", [treatments_service_1.TreatmentsService])
], TreatmentsController);
//# sourceMappingURL=treatments.controller.js.map