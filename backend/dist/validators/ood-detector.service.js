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
exports.OodDetectorService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const supported_classes_service_1 = require("./supported-classes.service");
const diagnosis_result_types_1 = require("../common/types/diagnosis-result.types");
let OodDetectorService = class OodDetectorService {
    constructor(supportedClasses, configService) {
        this.supportedClasses = supportedClasses;
        this.configService = configService;
        this.MAX_PROB_THRESHOLD =
            this.configService.get('MAX_PROB_THRESHOLD') || 0.4;
        this.ENTROPY_THRESHOLD =
            this.configService.get('ENTROPY_THRESHOLD') || 2.5;
        this.TOP_K_MARGIN_THRESHOLD =
            this.configService.get('TOP_K_MARGIN_THRESHOLD') || 0.15;
    }
    analyze(probabilities, labels) {
        const maxProb = Math.max(...probabilities);
        const entropy = this.calculateEntropy(probabilities);
        const topKAnalysis = this.analyzeTopK(probabilities, labels, 3);
        if (maxProb < this.MAX_PROB_THRESHOLD) {
            return {
                isInDistribution: false,
                reason: diagnosis_result_types_1.OODReason.LOW_MAX_PROBABILITY,
                message: `This doesn't appear to be any plant leaf in our database.\n` +
                    `Maximum confidence: ${Math.round(maxProb * 100)}%\n\n` +
                    `Please ensure you're scanning actual plant tissue.`,
                maxProbability: maxProb,
                entropy,
            };
        }
        if (entropy > this.ENTROPY_THRESHOLD) {
            return {
                isInDistribution: false,
                reason: diagnosis_result_types_1.OODReason.HIGH_ENTROPY,
                message: `Model is very uncertain about this image.\n` +
                    `Uncertainty score: ${entropy.toFixed(2)}\n\n` +
                    `Top candidates:\n${this.formatTopK(topKAnalysis)}\n\n` +
                    `This may indicate:\n` +
                    `• Mixed plant species in frame\n` +
                    `• Multiple diseases present\n` +
                    `• Non-plant object`,
                maxProbability: maxProb,
                entropy,
            };
        }
        if (topKAnalysis.isDifferentCrops) {
            return {
                isInDistribution: false,
                reason: diagnosis_result_types_1.OODReason.CONFLICTING_CROPS,
                message: `Detected conflicting plant types:\n${this.formatTopK(topKAnalysis)}\n\n` +
                    `Please ensure frame contains only one plant type.`,
                maxProbability: maxProb,
                entropy,
            };
        }
        if (topKAnalysis.margin < this.TOP_K_MARGIN_THRESHOLD) {
            return {
                isInDistribution: true,
                message: `Multiple diseases possible (close predictions):\n` +
                    `${this.formatTopK(topKAnalysis)}\n\n` +
                    `Recommendations:\n` +
                    `• Retake with better lighting\n` +
                    `• Focus on most diseased area\n` +
                    `• Consult expert if symptoms persist`,
                topCandidates: topKAnalysis.predictions,
            };
        }
        return {
            isInDistribution: true,
        };
    }
    calculateEntropy(probabilities) {
        let entropy = 0.0;
        for (const p of probabilities) {
            if (p > 0) {
                entropy -= p * Math.log(p);
            }
        }
        return entropy;
    }
    analyzeTopK(probabilities, labels, k) {
        const indexed = probabilities.map((prob, idx) => ({ idx, prob }));
        indexed.sort((a, b) => b.prob - a.prob);
        const topK = indexed.slice(0, k);
        const predictions = topK.map((item) => {
            const label = labels[item.idx];
            const [crop, disease] = label.split('___');
            return {
                crop,
                disease,
                probability: item.prob,
            };
        });
        const crops = new Set(predictions.map((p) => this.supportedClasses.normalizeCropName(p.crop)));
        const isDifferentCrops = crops.size > 1;
        const margin = predictions[0].probability - predictions[1].probability;
        return {
            predictions,
            isDifferentCrops,
            margin,
            crops: Array.from(crops),
        };
    }
    formatTopK(analysis) {
        return analysis.predictions
            .map((p) => `  ${Math.round(p.probability * 100)}% - ${p.crop} ${p.disease}`)
            .join('\n');
    }
};
exports.OodDetectorService = OodDetectorService;
exports.OodDetectorService = OodDetectorService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supported_classes_service_1.SupportedClassesService,
        config_1.ConfigService])
], OodDetectorService);
//# sourceMappingURL=ood-detector.service.js.map