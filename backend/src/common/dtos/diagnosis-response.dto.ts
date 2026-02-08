import { ApiProperty } from '@nestjs/swagger';
import { DiagnosisResult } from '@common/types/diagnosis-result.types';

export class DiagnosisResponseDto {
    @ApiProperty({
        description: 'Type of result',
        enum: [
            'success',
            'poorQuality',
            'outOfDistribution',
            'wrongCrop',
            'lowConfidence',
            'error',
        ],
    })
    type: string;

    @ApiProperty({ description: 'Disease name (if successful)', required: false })
    disease?: string;

    @ApiProperty({ description: 'Confidence score 0-1', required: false })
    confidence?: number;

    @ApiProperty({ description: 'Severity level', required: false })
    severity?: string;

    @ApiProperty({ description: 'Crop type', required: false })
    cropType?: string;

    @ApiProperty({ description: 'Full label from model', required: false })
    fullLabel?: string;

    @ApiProperty({ description: 'Error or info message', required: false })
    message?: string;

    @ApiProperty({ description: 'Selected crop (for mismatch)', required: false })
    selectedCrop?: string;

    @ApiProperty({ description: 'Detected crop (for mismatch)', required: false })
    detectedCrop?: string;

    static fromDiagnosisResult(result: DiagnosisResult): DiagnosisResponseDto {
        const dto = new DiagnosisResponseDto();
        dto.type = result.type;

        switch (result.type) {
            case 'success':
                dto.disease = result.disease;
                dto.confidence = result.confidence;
                dto.severity = result.severity;
                dto.cropType = result.cropType;
                dto.fullLabel = result.fullLabel;
                break;

            case 'poorQuality':
            case 'outOfDistribution':
            case 'lowConfidence':
            case 'error':
                dto.message = result.message;
                break;

            case 'wrongCrop':
                dto.selectedCrop = result.selectedCrop;
                dto.detectedCrop = result.detectedCrop;
                dto.message = result.message;
                break;
        }

        return dto;
    }
}
