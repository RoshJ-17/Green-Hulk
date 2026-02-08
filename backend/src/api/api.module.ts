import { Module } from '@nestjs/common';
import { DiagnosisController } from './diagnosis.controller';
import { ScansController } from './scans.controller';
import { DiagnosisModule } from '@diagnosis/diagnosis.module';
import { ValidatorsModule } from '@validators/validators.module';
import { MlModule } from '@ml/ml.module';
import { DatabaseModule } from '@database/database.module';

@Module({
    imports: [DiagnosisModule, ValidatorsModule, MlModule, DatabaseModule],
    controllers: [DiagnosisController, ScansController],
})
export class ApiModule { }
