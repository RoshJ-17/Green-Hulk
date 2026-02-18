export declare class SupportedClassesService {
    private readonly MODEL_CLASSES;
    private readonly SUPPORTED_CROPS;
    private readonly CROP_STATISTICS;
    getSupportedCrops(): string[];
    isCropSupported(cropName: string): boolean;
    normalizeCropName(crop: string): string;
    getDiseasesForCrop(cropName: string, allLabels: string[]): string[];
    getCropStatistics(): Record<string, number>;
    isClassSupported(className: string): boolean;
}
