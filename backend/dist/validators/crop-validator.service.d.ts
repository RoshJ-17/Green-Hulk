import { SupportedClassesService } from './supported-classes.service';
import { PredictionValidatorService } from './prediction-validator.service';
import { ValidationResult } from '@common/types/diagnosis-result.types';
export declare class CropValidatorService {
    private readonly supportedClasses;
    private readonly predictionValidator;
    constructor(supportedClasses: SupportedClassesService, predictionValidator: PredictionValidatorService);
    validatePrediction(selectedCrop: string, predictedClassIndex: number, labels: string[], confidence: number): ValidationResult;
    private extractCropName;
}
