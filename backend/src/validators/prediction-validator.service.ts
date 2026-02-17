import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PredictionStatus } from '@common/types/diagnosis-result.types';

@Injectable()
export class PredictionValidatorService {
    private readonly CONFIDENCE_THRESHOLD: number;
    private readonly HIGH_CONFIDENCE_THRESHOLD: number;
    private readonly VERY_HIGH_CONFIDENCE: number;

    constructor(private readonly configService: ConfigService) {
        this.CONFIDENCE_THRESHOLD =
            this.configService.get<number>('CONFIDENCE_THRESHOLD') || 0.5;
        this.HIGH_CONFIDENCE_THRESHOLD =
            this.configService.get<number>('HIGH_CONFIDENCE_THRESHOLD') || 0.7;
        this.VERY_HIGH_CONFIDENCE =
            this.configService.get<number>('VERY_HIGH_CONFIDENCE') || 0.9;
    }

    getStatus(confidence: number): PredictionStatus {
        if (confidence < this.CONFIDENCE_THRESHOLD) {
            return PredictionStatus.UNKNOWN;
        } else if (confidence < this.HIGH_CONFIDENCE_THRESHOLD) {
            return PredictionStatus.LOW_CONFIDENCE;
        }
        return PredictionStatus.CONFIDENT;
    }

    getUserMessage(
        status: PredictionStatus,
        disease: string,
        confidence: number,
    ): string {
        const confidencePercent = Math.round(confidence * 100);

        switch (status) {
            case PredictionStatus.CONFIDENT:
                return `${disease} detected with ${confidencePercent}% confidence.`;

            case PredictionStatus.LOW_CONFIDENCE:
                return (
                    `Possibly ${disease} (${confidencePercent}% confidence).\n` +
                    `⚠️ Recommendation: Retake photo in better lighting or consult an expert.`
                );

            case PredictionStatus.UNKNOWN:
                return (
                    `Unable to identify this plant or disease.\n\n` +
                    `This may be:\n` +
                    `• A plant not in our database (14 crops supported)\n` +
                    `• Poor photo quality (blurry, dark, or unfocused)\n` +
                    `• Healthy plant tissue without disease symptoms\n` +
                    `• Non-plant object\n\n` +
                    `Please select from supported crops or retake with:\n` +
                    `✓ Good lighting (avoid shadows)\n` +
                    `✓ Focus on diseased leaf area\n` +
                    `✓ Stable camera (no motion blur)`
                );
        }
    }

    getSeverityFromConfidence(confidence: number): string {
        if (confidence < this.CONFIDENCE_THRESHOLD) return 'Unknown';
        if (confidence < this.HIGH_CONFIDENCE_THRESHOLD) return 'Early Stage';
        if (confidence < this.VERY_HIGH_CONFIDENCE) return 'Medium';
        return 'Severe';
    }
}
