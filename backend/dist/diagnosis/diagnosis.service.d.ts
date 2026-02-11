import { ModelLoaderService } from '@ml/model-loader.service';
import { LabelLoaderService } from '@ml/label-loader.service';
import { ImageProcessorService } from '@image/image-processor.service';
import { QualityCheckerService } from '@image/quality-checker.service';
import { OodDetectorService } from '@validators/ood-detector.service';
import { CropValidatorService } from '@validators/crop-validator.service';
import { PredictionValidatorService } from '@validators/prediction-validator.service';
import { DiagnosisResult } from '@common/types/diagnosis-result.types';
export declare class DiagnosisService {
    private readonly modelLoader;
    private readonly labelLoader;
    private readonly imageProcessor;
    private readonly qualityChecker;
    private readonly oodDetector;
    private readonly cropValidator;
    private readonly predictionValidator;
    private readonly logger;
    constructor(modelLoader: ModelLoaderService, labelLoader: LabelLoaderService, imageProcessor: ImageProcessorService, qualityChecker: QualityCheckerService, oodDetector: OodDetectorService, cropValidator: CropValidatorService, predictionValidator: PredictionValidatorService);
    diagnose(imageBuffer: Buffer, selectedCrop: string): Promise<DiagnosisResult>;
    private getMaxIndex;
}
