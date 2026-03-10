import { Injectable } from "@nestjs/common";
import { SupportedClassesService } from "./supported-classes.service";
import { PredictionValidatorService } from "./prediction-validator.service";
import { ValidationResult } from "@common/types/diagnosis-result.types";
import { ConfigService } from "@nestjs/config";

@Injectable()
export class CropValidatorService {
  private readonly LOW_CONFIDENCE_THRESHOLD: number;

  constructor(
    private readonly supportedClasses: SupportedClassesService,
    private readonly predictionValidator: PredictionValidatorService,
    private readonly configService: ConfigService,
  ) {
    // Real-world field images are often noisier than benchmark data.
    // 0.35 avoids over-rejecting valid scans while still filtering weak guesses.
    this.LOW_CONFIDENCE_THRESHOLD =
      this.configService.get<number>("CONFIDENCE_THRESHOLD") || 0.35;
  }

  /**
   * Pick a selected-crop candidate when top-1 belongs to a different crop,
   * but the selected crop is still very close in probability.
   */
  resolveBestIndexForSelectedCrop(
    selectedCrop: string,
    labels: string[],
    probabilities: number[],
  ): number {
    const topIndex = probabilities.indexOf(Math.max(...probabilities));

    if (selectedCrop.toLowerCase() === "any") {
      return topIndex;
    }

    const topLabel = labels[topIndex];
    const topCrop = this.extractCropName(topLabel);
    const normalizedSelected = this.supportedClasses.normalizeCropName(selectedCrop);
    const normalizedTop = this.supportedClasses.normalizeCropName(topCrop);

    // Already matching selected crop.
    if (normalizedSelected === normalizedTop) {
      return topIndex;
    }

    // Find best class inside selected crop.
    let selectedBestIndex = -1;
    let selectedBestProb = -1;

    for (let i = 0; i < labels.length; i++) {
      const labelCrop = this.extractCropName(labels[i]);
      const normalizedLabelCrop = this.supportedClasses.normalizeCropName(labelCrop);
      if (normalizedLabelCrop === normalizedSelected && probabilities[i] > selectedBestProb) {
        selectedBestProb = probabilities[i];
        selectedBestIndex = i;
      }
    }

    if (selectedBestIndex === -1) {
      return topIndex;
    }

    const topProb = probabilities[topIndex];
    const closeAbsoluteGap = topProb - selectedBestProb <= 0.08;
    const closeRelativeGap = selectedBestProb >= topProb * 0.8;

    // If selected crop is competitively close, prefer it to avoid false wrong-crop rejects.
    return closeAbsoluteGap || closeRelativeGap ? selectedBestIndex : topIndex;
  }

  validatePrediction(
    selectedCrop: string,
    predictedClassIndex: number,
    labels: string[],
    confidence: number,
  ): ValidationResult {
    const predictedLabel = labels[predictedClassIndex];
    const predictedCrop = this.extractCropName(predictedLabel);

    // When "any" is passed (multi-crop scan), skip crop-match check and
    // accept whatever crop the model detected.
    const skipCropCheck = selectedCrop.toLowerCase() === 'any';

    if (!skipCropCheck) {
      const normalizedSelected =
        this.supportedClasses.normalizeCropName(selectedCrop);
      const normalizedPredicted =
        this.supportedClasses.normalizeCropName(predictedCrop);

      // Check 1: Crop mismatch
      if (normalizedSelected !== normalizedPredicted) {
        return {
          type: "wrongCrop",
          selectedCrop,
          detectedCrop: predictedCrop,
          message:
            `This appears to be ${predictedCrop}, but you selected ${selectedCrop}.\n\n` +
            `Options:\n` +
            `• Change selection to ${predictedCrop}\n` +
            `• Retake photo of ${selectedCrop} leaf`,
        };
      }
    }

    // Check 2: Low quality/confidence
    if (confidence < this.LOW_CONFIDENCE_THRESHOLD) {
      return {
        type: "lowQuality",
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
    const disease = predictedLabel.split("___")[1];
    const severity =
      this.predictionValidator.getSeverityFromConfidence(confidence);

    return {
      type: "valid",
      disease,
      confidence,
      severity,
    };
  }

  private extractCropName(label: string): string {
    return label.split("___")[0];
  }
}
