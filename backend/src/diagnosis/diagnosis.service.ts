import { Injectable, Logger } from '@nestjs/common';
import { ModelLoaderService } from '@ml/model-loader.service';
import { LabelLoaderService } from '@ml/label-loader.service';
import { ImageProcessorService } from '@image/image-processor.service';
import { QualityCheckerService } from '@image/quality-checker.service';
import { OodDetectorService } from '@validators/ood-detector.service';
import { CropValidatorService } from '@validators/crop-validator.service';
import { PredictionValidatorService } from '@validators/prediction-validator.service';
import { DiagnosisResult } from '@common/types/diagnosis-result.types';
import * as sharp from 'sharp';

@Injectable()
export class DiagnosisService {
    private readonly logger = new Logger(DiagnosisService.name);

    constructor(
        private readonly modelLoader: ModelLoaderService,
        private readonly labelLoader: LabelLoaderService,
        private readonly imageProcessor: ImageProcessorService,
        private readonly qualityChecker: QualityCheckerService,
        private readonly oodDetector: OodDetectorService,
        private readonly cropValidator: CropValidatorService,
        private readonly predictionValidator: PredictionValidatorService,
    ) { }

    /**
     * Main diagnosis pipeline
     * Orchestrates all steps from image loading to final result
     */
    async diagnose(
        imageBuffer: Buffer,
        selectedCrop: string,
    ): Promise<DiagnosisResult> {
        const startTime = Date.now();

        try {
            // Step 1: Load image and get metadata
            const image = sharp(imageBuffer);
            const metadata = await image.metadata();

            if (!metadata.width || !metadata.height) {
                return {
                    type: 'error',
                    message: 'Invalid image: missing dimensions',
                };
            }

            this.logger.debug(
                `Image loaded: ${metadata.width}x${metadata.height}, format: ${metadata.format}`,
            );

            // Step 2: Quality checks
            const qualityResult = await this.qualityChecker.checkImageQuality(
                imageBuffer,
                { width: metadata.width, height: metadata.height },
            );

            // Reject critical quality issues
            if (qualityResult.hasCriticalIssues) {
                this.logger.warn('Image rejected due to critical quality issues');
                return {
                    type: 'poorQuality',
                    message: this.qualityChecker.getUserFriendlyMessage(qualityResult),
                    issues: qualityResult.issues,
                };
            }

            // Step 3: Preprocess image
            this.logger.debug('Preprocessing image...');
            const preprocessed = await this.imageProcessor.preprocess(imageBuffer);

            // Step 4: Run inference
            this.logger.debug('Running inference...');
            const probabilities = await this.modelLoader.runInference(preprocessed);

            // Step 5: Out-of-distribution detection
            const labels = this.labelLoader.getAllLabels();
            const oodResult = this.oodDetector.analyze(probabilities, labels);

            if (!oodResult.isInDistribution) {
                this.logger.warn(`OOD detected: ${oodResult.reason}`);
                return {
                    type: 'outOfDistribution',
                    message: oodResult.message!,
                    reason: oodResult.reason!,
                    maxProbability: oodResult.maxProbability,
                    entropy: oodResult.entropy,
                };
            }

            // Step 6: Get top prediction
            const maxIndex = this.getMaxIndex(probabilities);
            const confidence = probabilities[maxIndex];

            this.logger.debug(
                `Top prediction: index ${maxIndex}, confidence ${(confidence * 100).toFixed(2)}%`,
            );

            // Step 7: Validate prediction vs selected crop
            const validation = this.cropValidator.validatePrediction(
                selectedCrop,
                maxIndex,
                labels,
                confidence,
            );

            if (validation.type === 'wrongCrop') {
                this.logger.warn(
                    `Crop mismatch: selected ${validation.selectedCrop}, detected ${validation.detectedCrop}`,
                );
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

            // Step 8: Success!
            const validResult = validation;
            const fullLabel = labels[maxIndex];

            const elapsedTime = Date.now() - startTime;
            this.logger.log(
                `Diagnosis completed in ${elapsedTime}ms: ${validResult.disease} (${(confidence * 100).toFixed(2)}%)`,
            );

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
        } catch (error) {
            this.logger.error(`Diagnosis failed: ${error.message}`, error.stack);
            return {
                type: 'error',
                message: `Diagnosis failed: ${error.message}`,
                stackTrace: error.stack,
            };
        }
    }

    private getMaxIndex(probabilities: number[]): number {
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
}
