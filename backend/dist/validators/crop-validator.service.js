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
Object.defineProperty(exports, "__esModule", { value: true });
exports.CropValidatorService = void 0;
const common_1 = require("@nestjs/common");
const supported_classes_service_1 = require("./supported-classes.service");
const prediction_validator_service_1 = require("./prediction-validator.service");
let CropValidatorService = class CropValidatorService {
    constructor(supportedClasses, predictionValidator) {
        this.supportedClasses = supportedClasses;
        this.predictionValidator = predictionValidator;
    }
    validatePrediction(selectedCrop, predictedClassIndex, labels, confidence) {
        const predictedLabel = labels[predictedClassIndex];
        const predictedCrop = this.extractCropName(predictedLabel);
        const normalizedSelected = this.supportedClasses.normalizeCropName(selectedCrop);
        const normalizedPredicted = this.supportedClasses.normalizeCropName(predictedCrop);
        if (normalizedSelected !== normalizedPredicted) {
            return {
                type: "wrongCrop",
                selectedCrop,
                detectedCrop: predictedCrop,
                message: `This appears to be ${predictedCrop}, but you selected ${selectedCrop}.\n\n` +
                    `Options:\n` +
                    `• Change selection to ${predictedCrop}\n` +
                    `• Retake photo of ${selectedCrop} leaf`,
            };
        }
        if (confidence < 0.5) {
            return {
                type: "lowQuality",
                message: `Image quality too poor for accurate detection.\n\n` +
                    `Please ensure:\n` +
                    `✓ Good lighting (natural daylight preferred)\n` +
                    `✓ Focus on diseased leaf area\n` +
                    `✓ Stable camera (no blur)\n` +
                    `✓ Close-up view of symptoms`,
            };
        }
        const disease = predictedLabel.split("___")[1];
        const severity = this.predictionValidator.getSeverityFromConfidence(confidence);
        return {
            type: "valid",
            disease,
            confidence,
            severity,
        };
    }
    extractCropName(label) {
        return label.split("___")[0];
    }
};
exports.CropValidatorService = CropValidatorService;
exports.CropValidatorService = CropValidatorService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supported_classes_service_1.SupportedClassesService,
        prediction_validator_service_1.PredictionValidatorService])
], CropValidatorService);
//# sourceMappingURL=crop-validator.service.js.map