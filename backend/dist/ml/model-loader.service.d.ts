import { OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
export declare class ModelLoaderService implements OnModuleInit {
    private readonly configService;
    private readonly logger;
    private isLoaded;
    private readonly TFLITE_SERVICE_URL;
    private readonly EXPECTED_INPUT_SIZE;
    private readonly EXPECTED_OUTPUT_CLASSES;
    constructor(configService: ConfigService);
    onModuleInit(): Promise<void>;
    checkTFLiteService(): Promise<boolean>;
    isModelLoaded(): boolean;
    runInference(input: Float32Array): Promise<number[]>;
    loadModel(): Promise<boolean>;
    dispose(): void;
}
