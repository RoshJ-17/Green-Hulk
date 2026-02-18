import { OnModuleInit } from "@nestjs/common";
export declare class ModelLoaderService implements OnModuleInit {
    private readonly logger;
    private isLoaded;
    private readonly TFLITE_SERVICE_URL;
    private readonly EXPECTED_INPUT_SIZE;
    private readonly EXPECTED_OUTPUT_CLASSES;
    constructor();
    onModuleInit(): Promise<void>;
    checkTFLiteService(): Promise<boolean>;
    isModelLoaded(): boolean;
    runInference(input: Float32Array): Promise<number[]>;
    loadModel(): Promise<boolean>;
    dispose(): void;
}
