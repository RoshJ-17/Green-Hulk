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
exports.PredictionValidatorService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const diagnosis_result_types_1 = require("../common/types/diagnosis-result.types");
let PredictionValidatorService = class PredictionValidatorService {
    constructor(configService) {
        this.configService = configService;
        this.CONFIDENCE_THRESHOLD =
            this.configService.get("CONFIDENCE_THRESHOLD") || 0.5;
        this.HIGH_CONFIDENCE_THRESHOLD =
            this.configService.get("HIGH_CONFIDENCE_THRESHOLD") || 0.7;
        this.VERY_HIGH_CONFIDENCE =
            this.configService.get("VERY_HIGH_CONFIDENCE") || 0.9;
    }
    getStatus(confidence) {
        if (confidence < this.CONFIDENCE_THRESHOLD) {
            return diagnosis_result_types_1.PredictionStatus.UNKNOWN;
        }
        else if (confidence < this.HIGH_CONFIDENCE_THRESHOLD) {
            return diagnosis_result_types_1.PredictionStatus.LOW_CONFIDENCE;
        }
        return diagnosis_result_types_1.PredictionStatus.CONFIDENT;
    }
    getUserMessage(status, disease, confidence) {
        const confidencePercent = Math.round(confidence * 100);
        switch (status) {
            case diagnosis_result_types_1.PredictionStatus.CONFIDENT:
                return `${disease} detected with ${confidencePercent}% confidence.`;
            case diagnosis_result_types_1.PredictionStatus.LOW_CONFIDENCE:
                return (`Possibly ${disease} (${confidencePercent}% confidence).\n` +
                    `⚠️ Recommendation: Retake photo in better lighting or consult an expert.`);
            case diagnosis_result_types_1.PredictionStatus.UNKNOWN:
                return (`Unable to identify this plant or disease.\n\n` +
                    `This may be:\n` +
                    `• A plant not in our database (14 crops supported)\n` +
                    `• Poor photo quality (blurry, dark, or unfocused)\n` +
                    `• Healthy plant tissue without disease symptoms\n` +
                    `• Non-plant object\n\n` +
                    `Please select from supported crops or retake with:\n` +
                    `✓ Good lighting (avoid shadows)\n` +
                    `✓ Focus on diseased leaf area\n` +
                    `✓ Stable camera (no motion blur)`);
        }
    }
    getSeverityFromConfidence(confidence) {
        if (confidence < this.CONFIDENCE_THRESHOLD)
            return "Unknown";
        if (confidence < this.HIGH_CONFIDENCE_THRESHOLD)
            return "Early Stage";
        if (confidence < this.VERY_HIGH_CONFIDENCE)
            return "Medium";
        return "Severe";
    }
};
exports.PredictionValidatorService = PredictionValidatorService;
exports.PredictionValidatorService = PredictionValidatorService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], PredictionValidatorService);
//# sourceMappingURL=prediction-validator.service.js.map