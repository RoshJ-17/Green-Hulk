import { Module } from '@nestjs/common';
import { DiagnosisService } from './diagnosis.service';
import { MlModule } from '@ml/ml.module';
import { ImageModule } from '@image/image.module';
import { ValidatorsModule } from '@validators/validators.module';

@Module({
    imports: [MlModule, ImageModule, ValidatorsModule],
    providers: [DiagnosisService],
    exports: [DiagnosisService],
})
export class DiagnosisModule { }
