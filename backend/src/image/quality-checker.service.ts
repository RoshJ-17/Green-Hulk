import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ImageProcessorService } from './image-processor.service';
import {
    QualityCheckResult,
    QualityIssue,
    IssueType,
    IssueSeverity,
} from '@common/types/diagnosis-result.types';

@Injectable()
export class QualityCheckerService {
    private readonly logger = new Logger(QualityCheckerService.name);

    private readonly BLUR_THRESHOLD: number;
    private readonly MIN_BRIGHTNESS: number;
    private readonly MAX_BRIGHTNESS: number;
    private readonly MIN_RESOLUTION = 224;

    constructor(
        private readonly imageProcessor: ImageProcessorService,
        private readonly configService: ConfigService,
    ) {
        this.BLUR_THRESHOLD =
            this.configService.get<number>('BLUR_THRESHOLD') || 100.0;
        this.MIN_BRIGHTNESS =
            this.configService.get<number>('MIN_BRIGHTNESS') || 50.0;
        this.MAX_BRIGHTNESS =
            this.configService.get<number>('MAX_BRIGHTNESS') || 200.0;
    }

    async checkImageQuality(
        imageBuffer: Buffer,
        metadata: { width: number; height: number },
    ): Promise<QualityCheckResult> {
        const issues: QualityIssue[] = [];

        // Check 1: Blur detection
        const blurScore = await this.imageProcessor.calculateBlurScore(imageBuffer);
        this.logger.debug(`Blur score: ${blurScore.toFixed(2)}`);

        if (blurScore < this.BLUR_THRESHOLD) {
            issues.push({
                type: IssueType.BLUR,
                severity: IssueSeverity.CRITICAL,
                message: `Image is too blurry (score: ${blurScore.toFixed(0)})`,
                suggestion: 'Hold camera steady and tap to focus before capturing.',
            });
        }

        // Check 2: Brightness
        const brightness =
            await this.imageProcessor.calculateBrightness(imageBuffer);
        this.logger.debug(`Brightness: ${brightness.toFixed(2)}`);

        if (brightness < this.MIN_BRIGHTNESS) {
            issues.push({
                type: IssueType.DARKNESS,
                severity: IssueSeverity.WARNING,
                message: `Image is too dark (brightness: ${brightness.toFixed(0)})`,
                suggestion: 'Use natural daylight or turn on flash.',
            });
        } else if (brightness > this.MAX_BRIGHTNESS) {
            issues.push({
                type: IssueType.OVEREXPOSURE,
                severity: IssueSeverity.WARNING,
                message: `Image is overexposed (brightness: ${brightness.toFixed(0)})`,
                suggestion: 'Move to shade or reduce direct sunlight.',
            });
        }

        // Check 3: Resolution
        if (metadata.width < this.MIN_RESOLUTION || metadata.height < this.MIN_RESOLUTION) {
            issues.push({
                type: IssueType.LOW_RESOLUTION,
                severity: IssueSeverity.CRITICAL,
                message: `Image resolution too low (${metadata.width}x${metadata.height})`,
                suggestion: 'Use camera at full resolution.',
            });
        }

        const hasCriticalIssues = issues.some(
            (issue) => issue.severity === IssueSeverity.CRITICAL,
        );

        return {
            isGood: issues.length === 0,
            issues,
            hasCriticalIssues,
        };
    }

    getUserFriendlyMessage(result: QualityCheckResult): string {
        if (result.isGood) {
            return 'Image quality is good ✓';
        }

        const critical = result.issues.filter(
            (i) => i.severity === IssueSeverity.CRITICAL,
        );
        const warnings = result.issues.filter(
            (i) => i.severity === IssueSeverity.WARNING,
        );

        const lines: string[] = [];

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
}
