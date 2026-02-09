import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as tf from '@tensorflow/tfjs';
import * as fs from 'fs/promises';
import * as path from 'path';
import {
    ModelNotFoundException,
    ModelCorruptedException,
    ModelIncompatibleException,
} from '@common/exceptions/custom.exceptions';

interface ModelLoadResult {
    isSuccess: boolean;
    error?: string;
    inputShape?: number[];
    outputShape?: number[];
    modelSizeMB?: number;
}

@Injectable()
export class ModelLoaderService implements OnModuleInit {
    private readonly logger = new Logger(ModelLoaderService.name);
    private model: tf.GraphModel | null = null;
    private isLoaded = false;

    private readonly EXPECTED_INPUT_SIZE = 224;
    private readonly EXPECTED_OUTPUT_CLASSES = 38;
    private readonly MIN_MODEL_SIZE = 1_000_000; // 1 MB
    private readonly MAX_MODEL_SIZE = 50_000_000; // 50 MB

    constructor(private readonly configService: ConfigService) { }

    async onModuleInit() {
        this.logger.log('Initializing model loader...');
        const result = await this.loadModel();
        if (!result.isSuccess) {
            this.logger.warn(`Model not loaded: ${result.error}`);
            this.logger.warn('Server will start without ML inference capability');
            this.logger.warn('Add model files and restart to enable diagnosis features');
            // Don't throw - allow server to start without model
            return;
        }
        this.logger.log('Model loaded successfully');
        this.logger.log(
            `Input shape: ${result.inputShape}, Output shape: ${result.outputShape}`,
        );
    }

    async loadModel(): Promise<ModelLoadResult> {
        try {
            const modelPath = this.configService.get<string>('MODEL_PATH');

            if (!modelPath) {
                throw new ModelNotFoundException('MODEL_PATH not configured');
            }

            // Step 1: Verify model file exists
            const modelJsonPath = path.resolve(modelPath);
            const modelDir = path.dirname(modelJsonPath);

            try {
                await fs.access(modelJsonPath);
            } catch {
                throw new ModelNotFoundException(modelJsonPath);
            }

            // Step 2: Verify file integrity
            const stats = await fs.stat(modelJsonPath);
            if (stats.size < 100) {
                // JSON file should be at least 100 bytes
                throw new ModelCorruptedException(
                    `Model JSON file too small (${stats.size} bytes)`,
                );
            }

            // Step 3: Load model
            this.logger.log(`Loading model from: ${modelJsonPath}`);
            this.model = await tf.loadGraphModel(`file://${modelJsonPath}`);

            // Step 4: Verify model architecture
            const inputShape = this.model.inputs[0].shape!;
            const outputShape = this.model.outputs[0].shape!;

            this.logger.log(`Model input shape: ${inputShape}`);
            this.logger.log(`Model output shape: ${outputShape}`);

            // Verify input shape: [null/1, 224, 224, 3]
            if (
                inputShape.length !== 4 ||
                inputShape[1] !== this.EXPECTED_INPUT_SIZE ||
                inputShape[2] !== this.EXPECTED_INPUT_SIZE ||
                inputShape[3] !== 3
            ) {
                throw new ModelIncompatibleException(
                    `Invalid input shape: ${inputShape}. Expected: [batch, 224, 224, 3]`,
                );
            }

            // Verify output shape: [null/1, 38]
            if (
                outputShape.length !== 2 ||
                outputShape[1] !== this.EXPECTED_OUTPUT_CLASSES
            ) {
                throw new ModelIncompatibleException(
                    `Invalid output shape: ${outputShape}. Expected: [batch, 38]`,
                );
            }

            // Step 5: Calculate model size (approximate)
            const modelFiles = await fs.readdir(modelDir);
            let totalSize = 0;
            for (const file of modelFiles) {
                if (file.endsWith('.bin') || file.endsWith('.json')) {
                    const filePath = path.join(modelDir, file);
                    const fileStats = await fs.stat(filePath);
                    totalSize += fileStats.size;
                }
            }

            this.isLoaded = true;
            return {
                isSuccess: true,
                inputShape: inputShape as number[],
                outputShape: outputShape as number[],
                modelSizeMB: totalSize / (1024 * 1024),
            };
        } catch (error) {
            if (
                error instanceof ModelNotFoundException ||
                error instanceof ModelCorruptedException ||
                error instanceof ModelIncompatibleException
            ) {
                return {
                    isSuccess: false,
                    error: error.message,
                };
            }

            return {
                isSuccess: false,
                error: `Unexpected error loading model: ${error.message}`,
            };
        }
    }

    getModel(): tf.GraphModel {
        if (!this.isLoaded || !this.model) {
            throw new Error('Model not loaded. Call loadModel() first.');
        }
        return this.model;
    }

    isModelLoaded(): boolean {
        return this.isLoaded;
    }

    /**
     * Run inference on preprocessed image data
     * @param input Float32Array of shape [1, 224, 224, 3] with values in [0, 1]
     * @returns Probability distribution over 38 classes
     */
    async runInference(input: Float32Array): Promise<number[]> {
        if (!this.isLoaded || !this.model) {
            throw new Error('Model not loaded');
        }

        // Create tensor from input
        const inputTensor = tf.tensor4d(input, [1, 224, 224, 3]);

        try {
            // Run inference
            const outputTensor = this.model.predict(inputTensor) as tf.Tensor;

            // Get probabilities
            const probabilities = await outputTensor.data();

            // Clean up tensors
            inputTensor.dispose();
            outputTensor.dispose();

            return Array.from(probabilities);
        } catch (error) {
            inputTensor.dispose();
            throw new Error(`Inference failed: ${error.message}`);
        }
    }

    dispose() {
        if (this.model) {
            this.model.dispose();
            this.model = null;
            this.isLoaded = false;
            this.logger.log('Model disposed');
        }
    }
}
