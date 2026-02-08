import { Injectable } from '@nestjs/common';
import { SupportedClassesService } from './supported-classes.service';
import { PredictionValidatorService } from './prediction-validator.service';
import { ValidationResult } from '@common/types/diagnosis-result.types';

@Injectable()
export class CropValidatorService {
    constructor(
        private readonly supportedClasses: SupportedClassesService,
        private readonly predictionValidator: PredictionValidatorService,
    ) { }

    validatePrediction(
        selectedCrop: string,
        predictedClassIndex: number,
        labels: string[],
        confidence: number,
    ): ValidationResult {
        const predictedLabel = labels[predictedClassIndex];
        const predictedCrop = this.extractCropName(predictedLabel);
        const normalizedSelected = this.supportedClasses.normalizeCropName(selectedCrop);
        const normalizedPredicted = this.supportedClasses.normalizeCropName(predictedCrop);

        // Check 1: Crop mismatch
        if (normalizedSelected !== normalizedPredicted) {
            return {
                type: 'wrongCrop',
                selectedCrop,
                detectedCrop: predictedCrop,
                message:
                    `This appears to be ${predictedCrop}, but you selected ${selectedCrop}.\n\n` +
                    `Options:\n` +
                    `• Change selection to ${predictedCrop}\n` +
                    `• Retake photo of ${selectedCrop} leaf`,
            };
        }

        // Check 2: Low quality/confidence
        if (confidence < 0.5) {
            return {
                type: 'lowQuality',
                message:
                    `Image quality too poor for accurate detection.\n\n` +
                    `Please ensure:\n` +
                    `✓ Good lighting (natural daylight preferred)\n` +
                    `✓ Focus on diseased leaf area\n` +
                    `✓ Stable camera (no blur)\n` +
                    `✓ Close-up view of symptoms`,
            };
        }

        // Check 3: Success
        const disease = predictedLabel.split('___')[1];
        const severity = this.predictionValidator.getSeverityFromConfidence(confidence);

        return {
            type: 'valid',
            disease,
            confidence,
            severity,
        };
    }

    private extractCropName(label: string): string {
        return label.split('___')[0];
    }
}
