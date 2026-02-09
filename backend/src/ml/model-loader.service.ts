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

    constructor(private readonly configService: ConfigService) { }

    async onModuleInit() {
        this.logger.log('Initializing model loader...');

        // Model loading disabled due to environment incompatibility with TensorFlow.js / TFLite
        this.logger.warn('Model loading disabled: Environment incompatible with TensorFlow.js/TFLite');
        this.logger.warn('Server starting without ML inference capability.');
        return;
    }

    async loadModel(): Promise<ModelLoadResult> {
        return { isSuccess: false, error: 'Model loading disabled' };
    }

    getModel(): tf.GraphModel {
        throw new Error('Model not loaded.');
    }

    isModelLoaded(): boolean {
        return false;
    }

    async runInference(input: Float32Array): Promise<number[]> {
        throw new Error('Model not loaded');
    }

    dispose() {
        this.isLoaded = false;
    }
}
