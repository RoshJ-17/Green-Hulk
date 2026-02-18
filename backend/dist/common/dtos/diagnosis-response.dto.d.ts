import { DiagnosisResult } from '@common/types/diagnosis-result.types';
export declare class DiagnosisResponseDto {
    type: string;
    disease?: string;
    confidence?: number;
    severity?: string;
    cropType?: string;
    fullLabel?: string;
    message?: string;
    selectedCrop?: string;
    detectedCrop?: string;
    static fromDiagnosisResult(result: DiagnosisResult): DiagnosisResponseDto;
}
