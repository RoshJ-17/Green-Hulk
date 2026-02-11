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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var DiagnosisService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.DiagnosisService = void 0;
const common_1 = require("@nestjs/common");
const model_loader_service_1 = require("../ml/model-loader.service");
const label_loader_service_1 = require("../ml/label-loader.service");
const image_processor_service_1 = require("../image/image-processor.service");
const quality_checker_service_1 = require("../image/quality-checker.service");
const ood_detector_service_1 = require("../validators/ood-detector.service");
const crop_validator_service_1 = require("../validators/crop-validator.service");
const prediction_validator_service_1 = require("../validators/prediction-validator.service");
const sharp_1 = __importDefault(require("sharp"));
let DiagnosisService = DiagnosisService_1 = class DiagnosisService {
    constructor(modelLoader, labelLoader, imageProcessor, qualityChecker, oodDetector, cropValidator, predictionValidator) {
        this.modelLoader = modelLoader;
        this.labelLoader = labelLoader;
        this.imageProcessor = imageProcessor;
        this.qualityChecker = qualityChecker;
        this.oodDetector = oodDetector;
        this.cropValidator = cropValidator;
        this.predictionValidator = predictionValidator;
        this.logger = new common_1.Logger(DiagnosisService_1.name);
    }
    async diagnose(imageBuffer, selectedCrop) {
        const startTime = Date.now();
        try {
            const image = (0, sharp_1.default)(imageBuffer);
            const metadata = await image.metadata();
            if (!metadata.width || !metadata.height) {
                return {
                    type: 'error',
                    message: 'Invalid image: missing dimensions',
                };
            }
            this.logger.debug(`Image loaded: ${metadata.width}x${metadata.height}, format: ${metadata.format}`);
            const qualityResult = await this.qualityChecker.checkImageQuality(imageBuffer, { width: metadata.width, height: metadata.height });
            if (qualityResult.hasCriticalIssues) {
                this.logger.warn('Image rejected due to critical quality issues');
                return {
                    type: 'poorQuality',
                    message: this.qualityChecker.getUserFriendlyMessage(qualityResult),
                    issues: qualityResult.issues,
                };
            }
            this.logger.debug('Preprocessing image...');
            const preprocessed = await this.imageProcessor.preprocess(imageBuffer);
            this.logger.debug('Running inference...');
            const probabilities = await this.modelLoader.runInference(preprocessed);
            const labels = this.labelLoader.getAllLabels();
            const oodResult = this.oodDetector.analyze(probabilities, labels);
            if (!oodResult.isInDistribution) {
                this.logger.warn(`OOD detected: ${oodResult.reason}`);
                return {
                    type: 'outOfDistribution',
                    message: oodResult.message,
                    reason: oodResult.reason,
                    maxProbability: oodResult.maxProbability,
                    entropy: oodResult.entropy,
                };
            }
            const maxIndex = this.getMaxIndex(probabilities);
            const confidence = probabilities[maxIndex];
            this.logger.debug(`Top prediction: index ${maxIndex}, confidence ${(confidence * 100).toFixed(2)}%`);
            const validation = this.cropValidator.validatePrediction(selectedCrop, maxIndex, labels, confidence);
            if (validation.type === 'wrongCrop') {
                this.logger.warn(`Crop mismatch: selected ${validation.selectedCrop}, detected ${validation.detectedCrop}`);
                return {
                    type: 'wrongCrop',
                    selectedCrop: validation.selectedCrop,
                    detectedCrop: validation.detectedCrop,
                    message: validation.message,
                };
            }
            if (validation.type === 'lowQuality') {
                this.logger.warn('Low confidence prediction rejected');
                return {
                    type: 'lowConfidence',
                    message: validation.message,
                    confidence,
                };
            }
            const validResult = validation;
            const fullLabel = labels[maxIndex];
            const elapsedTime = Date.now() - startTime;
            this.logger.log(`Diagnosis completed in ${elapsedTime}ms: ${validResult.disease} (${(confidence * 100).toFixed(2)}%)`);
            return {
                type: 'success',
                disease: validResult.disease,
                confidence,
                severity: validResult.severity,
                cropType: selectedCrop,
                fullLabel,
                allProbabilities: probabilities,
                qualityWarnings: qualityResult.isGood ? undefined : qualityResult.issues,
            };
        }
        catch (error) {
            this.logger.error(`Diagnosis failed: ${error.message}`, error.stack);
            return {
                type: 'error',
                message: `Diagnosis failed: ${error.message}`,
                stackTrace: error.stack,
            };
        }
    }
    getMaxIndex(probabilities) {
        let maxValue = probabilities[0];
        let maxIndex = 0;
        for (let i = 1; i < probabilities.length; i++) {
            if (probabilities[i] > maxValue) {
                maxValue = probabilities[i];
                maxIndex = i;
            }
        }
        return maxIndex;
    }
};
exports.DiagnosisService = DiagnosisService;
exports.DiagnosisService = DiagnosisService = DiagnosisService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [model_loader_service_1.ModelLoaderService,
        label_loader_service_1.LabelLoaderService,
        image_processor_service_1.ImageProcessorService,
        quality_checker_service_1.QualityCheckerService,
        ood_detector_service_1.OodDetectorService,
        crop_validator_service_1.CropValidatorService,
        prediction_validator_service_1.PredictionValidatorService])
], DiagnosisService);
//# sourceMappingURL=diagnosis.service.js.map