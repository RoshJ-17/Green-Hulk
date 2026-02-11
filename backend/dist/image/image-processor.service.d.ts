import sharp from 'sharp';
export declare class ImageProcessorService {
    private readonly logger;
    private readonly INPUT_SIZE;
    loadImage(buffer: Buffer): Promise<sharp.Sharp>;
    preprocess(imageBuffer: Buffer): Promise<Float32Array>;
    private imageToFloat32Array;
    calculateBrightness(imageBuffer: Buffer): Promise<number>;
    calculateBlurScore(imageBuffer: Buffer): Promise<number>;
    private applyLaplacianKernel;
    private calculateVariance;
}
