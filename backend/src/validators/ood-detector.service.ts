import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SupportedClassesService } from './supported-classes.service';
import {
    OODResult,
    OODReason,
    TopPrediction,
    TopKAnalysis,
} from '@common/types/diagnosis-result.types';

@Injectable()
export class OodDetectorService {
    private readonly MAX_PROB_THRESHOLD: number;
    private readonly ENTROPY_THRESHOLD: number;
    private readonly TOP_K_MARGIN_THRESHOLD: number;

    constructor(
        private readonly supportedClasses: SupportedClassesService,
        private readonly configService: ConfigService,
    ) {
        this.MAX_PROB_THRESHOLD =
            this.configService.get<number>('MAX_PROB_THRESHOLD') || 0.4;
        this.ENTROPY_THRESHOLD =
            this.configService.get<number>('ENTROPY_THRESHOLD') || 2.5;
        this.TOP_K_MARGIN_THRESHOLD =
            this.configService.get<number>('TOP_K_MARGIN_THRESHOLD') || 0.15;
    }

    analyze(probabilities: number[], labels: string[]): OODResult {
        const maxProb = Math.max(...probabilities);
        const entropy = this.calculateEntropy(probabilities);
        const topKAnalysis = this.analyzeTopK(probabilities, labels, 3);

        // Detection Rule 1: All probabilities are very low
        if (maxProb < this.MAX_PROB_THRESHOLD) {
            return {
                isInDistribution: false,
                reason: OODReason.LOW_MAX_PROBABILITY,
                message:
                    `This doesn't appear to be any plant leaf in our database.\n` +
                    `Maximum confidence: ${Math.round(maxProb * 100)}%\n\n` +
                    `Please ensure you're scanning actual plant tissue.`,
                maxProbability: maxProb,
                entropy,
            };
        }

        // Detection Rule 2: High entropy (predictions scattered)
        if (entropy > this.ENTROPY_THRESHOLD) {
            return {
                isInDistribution: false,
                reason: OODReason.HIGH_ENTROPY,
                message:
                    `Model is very uncertain about this image.\n` +
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

        // Detection Rule 3: Top predictions from different crops
        if (topKAnalysis.isDifferentCrops) {
            return {
                isInDistribution: false,
                reason: OODReason.CONFLICTING_CROPS,
                message:
                    `Detected conflicting plant types:\n${this.formatTopK(topKAnalysis)}\n\n` +
                    `Please ensure frame contains only one plant type.`,
                maxProbability: maxProb,
                entropy,
            };
        }

        // Detection Rule 4: Small margin between top predictions
        if (topKAnalysis.margin < this.TOP_K_MARGIN_THRESHOLD) {
            return {
                isInDistribution: true,
                message:
                    `Multiple diseases possible (close predictions):\n` +
                    `${this.formatTopK(topKAnalysis)}\n\n` +
                    `Recommendations:\n` +
                    `• Retake with better lighting\n` +
                    `• Focus on most diseased area\n` +
                    `• Consult expert if symptoms persist`,
                topCandidates: topKAnalysis.predictions,
            };
        }

        // All checks passed - likely in-distribution
        return {
            isInDistribution: true,
        };
    }

    private calculateEntropy(probabilities: number[]): number {
        let entropy = 0.0;
        for (const p of probabilities) {
            if (p > 0) {
                entropy -= p * Math.log(p);
            }
        }
        return entropy;
    }

    private analyzeTopK(
        probabilities: number[],
        labels: string[],
        k: number,
    ): TopKAnalysis {
        // Create indexed array and sort by probability
        const indexed = probabilities.map((prob, idx) => ({ idx, prob }));
        indexed.sort((a, b) => b.prob - a.prob);

        // Get top K
        const topK = indexed.slice(0, k);

        const predictions: TopPrediction[] = topK.map((item) => {
            const label = labels[item.idx];
            const [crop, disease] = label.split('___');
            return {
                crop,
                disease,
                probability: item.prob,
            };
        });

        // Check if top K are from same crop
        const crops = new Set(
            predictions.map((p) => this.supportedClasses.normalizeCropName(p.crop)),
        );
        const isDifferentCrops = crops.size > 1;

        // Calculate margin between top 2
        const margin = predictions[0].probability - predictions[1].probability;

        return {
            predictions,
            isDifferentCrops,
            margin,
            crops: Array.from(crops),
        };
    }

    private formatTopK(analysis: TopKAnalysis): string {
        return analysis.predictions
            .map(
                (p) =>
                    `  ${Math.round(p.probability * 100)}% - ${p.crop} ${p.disease}`,
            )
            .join('\n');
    }
}
