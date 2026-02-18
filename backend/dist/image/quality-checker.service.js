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
var QualityCheckerService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.QualityCheckerService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const image_processor_service_1 = require("./image-processor.service");
const diagnosis_result_types_1 = require("../common/types/diagnosis-result.types");
let QualityCheckerService = QualityCheckerService_1 = class QualityCheckerService {
    constructor(imageProcessor, configService) {
        this.imageProcessor = imageProcessor;
        this.configService = configService;
        this.logger = new common_1.Logger(QualityCheckerService_1.name);
        this.MIN_RESOLUTION = 224;
        this.BLUR_THRESHOLD =
            this.configService.get('BLUR_THRESHOLD') || 100.0;
        this.MIN_BRIGHTNESS =
            this.configService.get('MIN_BRIGHTNESS') || 50.0;
        this.MAX_BRIGHTNESS =
            this.configService.get('MAX_BRIGHTNESS') || 200.0;
    }
    async checkImageQuality(imageBuffer, metadata) {
        const issues = [];
        const blurScore = await this.imageProcessor.calculateBlurScore(imageBuffer);
        this.logger.debug(`Blur score: ${blurScore.toFixed(2)}`);
        if (blurScore < this.BLUR_THRESHOLD) {
            issues.push({
                type: diagnosis_result_types_1.IssueType.BLUR,
                severity: diagnosis_result_types_1.IssueSeverity.CRITICAL,
                message: `Image is too blurry (score: ${blurScore.toFixed(0)})`,
                suggestion: 'Hold camera steady and tap to focus before capturing.',
            });
        }
        const brightness = await this.imageProcessor.calculateBrightness(imageBuffer);
        this.logger.debug(`Brightness: ${brightness.toFixed(2)}`);
        if (brightness < this.MIN_BRIGHTNESS) {
            issues.push({
                type: diagnosis_result_types_1.IssueType.DARKNESS,
                severity: diagnosis_result_types_1.IssueSeverity.WARNING,
                message: `Image is too dark (brightness: ${brightness.toFixed(0)})`,
                suggestion: 'Use natural daylight or turn on flash.',
            });
        }
        else if (brightness > this.MAX_BRIGHTNESS) {
            issues.push({
                type: diagnosis_result_types_1.IssueType.OVEREXPOSURE,
                severity: diagnosis_result_types_1.IssueSeverity.WARNING,
                message: `Image is overexposed (brightness: ${brightness.toFixed(0)})`,
                suggestion: 'Move to shade or reduce direct sunlight.',
            });
        }
        if (metadata.width < this.MIN_RESOLUTION || metadata.height < this.MIN_RESOLUTION) {
            issues.push({
                type: diagnosis_result_types_1.IssueType.LOW_RESOLUTION,
                severity: diagnosis_result_types_1.IssueSeverity.CRITICAL,
                message: `Image resolution too low (${metadata.width}x${metadata.height})`,
                suggestion: 'Use camera at full resolution.',
            });
        }
        const hasCriticalIssues = issues.some((issue) => issue.severity === diagnosis_result_types_1.IssueSeverity.CRITICAL);
        return {
            isGood: issues.length === 0,
            issues,
            hasCriticalIssues,
        };
    }
    getUserFriendlyMessage(result) {
        if (result.isGood) {
            return 'Image quality is good ✓';
        }
        const critical = result.issues.filter((i) => i.severity === diagnosis_result_types_1.IssueSeverity.CRITICAL);
        const warnings = result.issues.filter((i) => i.severity === diagnosis_result_types_1.IssueSeverity.WARNING);
        const lines = [];
        if (critical.length > 0) {
            lines.push('❌ Critical Issues:');
            for (const issue of critical) {
                lines.push(`  • ${issue.message}`);
                lines.push(`    → ${issue.suggestion}`);
            }
        }
        if (warnings.length > 0) {
            lines.push('⚠️ Warnings:');
            for (const issue of warnings) {
                lines.push(`  • ${issue.message}`);
                lines.push(`    → ${issue.suggestion}`);
            }
        }
        return lines.join('\n');
    }
};
exports.QualityCheckerService = QualityCheckerService;
exports.QualityCheckerService = QualityCheckerService = QualityCheckerService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [image_processor_service_1.ImageProcessorService,
        config_1.ConfigService])
], QualityCheckerService);
//# sourceMappingURL=quality-checker.service.js.map