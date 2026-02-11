import { DiagnosisService } from '@diagnosis/diagnosis.service';
import { SupportedClassesService } from '@validators/supported-classes.service';
import { LabelLoaderService } from '@ml/label-loader.service';
import { DiagnoseRequestDto } from '@common/dtos/diagnose-request.dto';
import { DiagnosisResponseDto } from '@common/dtos/diagnosis-response.dto';
import { Repository } from 'typeorm';
import { ScanRecord } from '@database/entities/scan-record.entity';
export declare class DiagnosisController {
    private readonly diagnosisService;
    private readonly supportedClasses;
    private readonly labelLoader;
    private readonly scanRepository;
    private readonly logger;
    constructor(diagnosisService: DiagnosisService, supportedClasses: SupportedClassesService, labelLoader: LabelLoaderService, scanRepository: Repository<ScanRecord>);
    diagnose(file: Express.Multer.File, dto: DiagnoseRequestDto): Promise<DiagnosisResponseDto>;
    getSupportedCrops(): {
        crops: string[];
        statistics: Record<string, number>;
    };
    getDiseasesForCrop(crop: string): {
        crop: string;
        diseases: string[];
        count: number;
    };
}
