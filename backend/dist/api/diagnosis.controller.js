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
var DiagnosisController_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.DiagnosisController = void 0;
const common_1 = require("@nestjs/common");
const platform_express_1 = require("@nestjs/platform-express");
const swagger_1 = require("@nestjs/swagger");
const diagnosis_service_1 = require("../diagnosis/diagnosis.service");
const supported_classes_service_1 = require("../validators/supported-classes.service");
const label_loader_service_1 = require("../ml/label-loader.service");
const diagnose_request_dto_1 = require("../common/dtos/diagnose-request.dto");
const diagnosis_response_dto_1 = require("../common/dtos/diagnosis-response.dto");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const scan_record_entity_1 = require("../database/entities/scan-record.entity");
let DiagnosisController = DiagnosisController_1 = class DiagnosisController {
    constructor(diagnosisService, supportedClasses, labelLoader, scanRepository) {
        this.diagnosisService = diagnosisService;
        this.supportedClasses = supportedClasses;
        this.labelLoader = labelLoader;
        this.scanRepository = scanRepository;
        this.logger = new common_1.Logger(DiagnosisController_1.name);
    }
    async diagnose(file, dto) {
        if (!file) {
            throw new common_1.BadRequestException('Image file is required');
        }
        const maxSize = 10 * 1024 * 1024;
        if (file.size > maxSize) {
            throw new common_1.BadRequestException('Image file too large (max 10MB)');
        }
        const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
        if (!allowedTypes.includes(file.mimetype)) {
            throw new common_1.BadRequestException('Invalid file type. Allowed: JPEG, PNG');
        }
        if (!this.supportedClasses.isCropSupported(dto.selectedCrop)) {
            throw new common_1.BadRequestException(`Unsupported crop: ${dto.selectedCrop}. Supported crops: ${this.supportedClasses.getSupportedCrops().join(', ')}`);
        }
        this.logger.log(`Diagnosing ${file.originalname} for crop: ${dto.selectedCrop}`);
        const result = await this.diagnosisService.diagnose(file.buffer, dto.selectedCrop);
        if (result.type === 'success') {
            const scanRecord = this.scanRepository.create({
                cropType: result.cropType,
                imagePath: file.originalname,
                diseaseName: result.disease,
                fullLabel: result.fullLabel,
                confidence: result.confidence,
                severity: result.severity,
                hadQualityWarnings: result.qualityWarnings !== undefined,
            });
            await this.scanRepository.save(scanRecord);
            this.logger.log(`Scan record saved: ID ${scanRecord.id}`);
        }
        return diagnosis_response_dto_1.DiagnosisResponseDto.fromDiagnosisResult(result);
    }
    getSupportedCrops() {
        return {
            crops: this.supportedClasses.getSupportedCrops(),
            statistics: this.supportedClasses.getCropStatistics(),
        };
    }
    getDiseasesForCrop(crop) {
        if (!this.supportedClasses.isCropSupported(crop)) {
            throw new common_1.BadRequestException(`Unsupported crop: ${crop}`);
        }
        const allLabels = this.labelLoader.getAllLabels();
        const diseases = this.supportedClasses.getDiseasesForCrop(crop, allLabels);
        return {
            crop,
            diseases,
            count: diseases.length,
        };
    }
};
exports.DiagnosisController = DiagnosisController;
__decorate([
    (0, common_1.Post)('diagnose'),
    (0, swagger_1.ApiOperation)({ summary: 'Diagnose plant disease from image' }),
    (0, swagger_1.ApiConsumes)('multipart/form-data'),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Diagnosis completed',
        type: diagnosis_response_dto_1.DiagnosisResponseDto,
    }),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('image')),
    __param(0, (0, common_1.UploadedFile)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, diagnose_request_dto_1.DiagnoseRequestDto]),
    __metadata("design:returntype", Promise)
], DiagnosisController.prototype, "diagnose", null);
__decorate([
    (0, common_1.Get)('crops'),
    (0, swagger_1.ApiOperation)({ summary: 'Get list of supported crops' }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'List of supported crops with disease counts',
    }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], DiagnosisController.prototype, "getSupportedCrops", null);
__decorate([
    (0, common_1.Get)('diseases/:crop'),
    (0, swagger_1.ApiOperation)({ summary: 'Get diseases for a specific crop' }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'List of diseases for the crop',
    }),
    __param(0, (0, common_1.Param)('crop')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], DiagnosisController.prototype, "getDiseasesForCrop", null);
exports.DiagnosisController = DiagnosisController = DiagnosisController_1 = __decorate([
    (0, swagger_1.ApiTags)('diagnosis'),
    (0, common_1.Controller)('api'),
    __param(3, (0, typeorm_1.InjectRepository)(scan_record_entity_1.ScanRecord)),
    __metadata("design:paramtypes", [diagnosis_service_1.DiagnosisService,
        supported_classes_service_1.SupportedClassesService,
        label_loader_service_1.LabelLoaderService,
        typeorm_2.Repository])
], DiagnosisController);
//# sourceMappingURL=diagnosis.controller.js.map