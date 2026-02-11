import { ConfigService } from '@nestjs/config';
import { PredictionStatus } from '@common/types/diagnosis-result.types';
export declare class PredictionValidatorService {
    private readonly configService;
    private readonly CONFIDENCE_THRESHOLD;
    private readonly HIGH_CONFIDENCE_THRESHOLD;
    private readonly VERY_HIGH_CONFIDENCE;
    constructor(configService: ConfigService);
    getStatus(confidence: number): PredictionStatus;
    getUserMessage(status: PredictionStatus, disease: string, confidence: number): string;
    getSeverityFromConfidence(confidence: number): string;
}
