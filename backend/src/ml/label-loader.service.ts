import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs/promises';
import * as path from 'path';
import { LabelLoadException } from '@common/exceptions/custom.exceptions';

interface LabelLoadResult {
    isSuccess: boolean;
    error?: string;
    classCount?: number;
    crops?: Set<string>;
}

@Injectable()
export class LabelLoaderService implements OnModuleInit {
    private readonly logger = new Logger(LabelLoaderService.name);
    private indexToLabel: Map<number, string> = new Map();
    private labelToIndex: Map<string, number> = new Map();
    private isLoaded = false;

    private readonly EXPECTED_CLASS_COUNT = 38;

    constructor(private readonly configService: ConfigService) { }

    async onModuleInit() {
        this.logger.log('Initializing label loader...');
        const result = await this.loadLabels();
        if (!result.isSuccess) {
            this.logger.warn(`Labels not loaded: ${result.error}`);
            this.logger.warn('Server will start without label mapping capability');
            // Don't throw - allow server to start without labels
            return;
        }
        this.logger.log(
            `Labels loaded successfully: ${result.classCount} classes, ${result.crops?.size} crops`,
        );
    }

    async loadLabels(): Promise<LabelLoadResult> {
        try {
            const labelsPath = this.configService.get<string>('LABELS_PATH');

            if (!labelsPath) {
                throw new LabelLoadException('LABELS_PATH not configured');
            }

            const resolvedPath = path.resolve(labelsPath);

            // Step 1: Load JSON file
            const jsonString = await fs.readFile(resolvedPath, 'utf-8');
            const jsonData: Record<string, number> = JSON.parse(jsonString);

            // Step 2: Verify class count
            const classCount = Object.keys(jsonData).length;
            if (classCount !== this.EXPECTED_CLASS_COUNT) {
                throw new LabelLoadException(
                    `Expected ${this.EXPECTED_CLASS_COUNT} classes, found ${classCount}`,
                );
            }

            // Step 3: Parse and validate
            this.indexToLabel.clear();
            this.labelToIndex.clear();

            const seenIndices = new Set<number>();
            const seenLabels = new Set<string>();

            for (const [label, index] of Object.entries(jsonData)) {
                // Validate index is number
                if (typeof index !== 'number') {
                    throw new LabelLoadException(
                        `Class "${label}" has non-integer index: ${index}`,
                    );
                }

                // Check for duplicates
                if (seenIndices.has(index)) {
                    throw new LabelLoadException(`Duplicate class index found: ${index}`);
                }

                if (seenLabels.has(label)) {
                    throw new LabelLoadException(`Duplicate class label found: "${label}"`);
                }

                seenIndices.add(index);
                seenLabels.add(label);

                this.labelToIndex.set(label, index);
                this.indexToLabel.set(index, label);
            }

            // Step 4: Verify continuous indexing (0 to 37)
            for (let i = 0; i < this.EXPECTED_CLASS_COUNT; i++) {
                if (!this.indexToLabel.has(i)) {
                    throw new LabelLoadException(
                        `Missing class index: ${i}. Indices must be continuous from 0 to ${this.EXPECTED_CLASS_COUNT - 1}`,
                    );
                }
            }

            // Step 5: Verify expected class names (spot check)
            this.validateExpectedClasses();

            // Step 6: Extract crop list
            const crops = this.extractCropList();

            this.isLoaded = true;
            return {
                isSuccess: true,
                classCount: this.indexToLabel.size,
                crops,
            };
        } catch (error) {
            if (error instanceof LabelLoadException) {
                return {
                    isSuccess: false,
                    error: error.message,
                };
            }

            if (error instanceof SyntaxError) {
                return {
                    isSuccess: false,
                    error: `Invalid JSON format: ${error.message}`,
                };
            }

            return {
                isSuccess: false,
                error: `Unexpected error: ${error.message}`,
            };
        }
    }

    private validateExpectedClasses(): void {
        // Spot check: Verify a few known classes exist
        const expectedSamples = [
            'Apple___Apple_scab',
            'Tomato___healthy',
            'Potato___Late_blight',
            'Corn_(maize)___Common_rust_',
        ];

        const missing: string[] = [];
        for (const expected of expectedSamples) {
            if (!this.labelToIndex.has(expected)) {
                missing.push(expected);
            }
        }

        if (missing.length > 0) {
            throw new LabelLoadException(
                `Missing expected PlantVillage classes: ${missing.join(', ')}. This may be a different dataset.`,
            );
        }

        // Check format: All labels should have "___" separator
        const invalidLabels = Array.from(this.labelToIndex.keys()).filter(
            (label) => !label.includes('___'),
        );

        if (invalidLabels.length > 0) {
            throw new LabelLoadException(
                `Invalid label format (missing "___" separator): ${invalidLabels.slice(0, 3).join(', ')}`,
            );
        }
    }

    private extractCropList(): Set<string> {
        const crops = new Set<string>();
        for (const label of this.labelToIndex.keys()) {
            const crop = label.split('___')[0];
            // Normalize: "Pepper,_bell" -> "Pepper", "Corn_(maize)" -> "Corn"
            const normalized = crop.split(/[,_(]/)[0].trim();
            crops.add(normalized);
        }
        return crops;
    }

    getLabelByIndex(index: number): string | undefined {
        return this.indexToLabel.get(index);
    }

    getIndexByLabel(label: string): number | undefined {
        return this.labelToIndex.get(label);
    }

    getAllLabels(): string[] {
        const labels: string[] = [];
        for (let i = 0; i < this.indexToLabel.size; i++) {
            const label = this.indexToLabel.get(i);
            if (label) {
                labels.push(label);
            }
        }
        return labels;
    }

    isLabelsLoaded(): boolean {
        return this.isLoaded;
    }

    getClassCount(): number {
        return this.indexToLabel.size;
    }
}
