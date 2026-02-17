import { Module } from '@nestjs/common';
import { DiagnosisController } from './diagnosis.controller';
import { ScansController } from './scans.controller';
import { PreferencesController } from './preferences.controller';
import { LocalizationController } from './localization.controller';
import { TreatmentsController } from './treatments.controller';
import { DiagnosisModule } from '@diagnosis/diagnosis.module';
import { DatabaseModule } from '@database/database.module';
import { LocalizationModule } from '@localization/localization.module';
import { TreatmentsModule } from '@treatments/treatments.module';
import { ValidatorsModule } from '@validators/validators.module';
import { MlModule } from '@ml/ml.module';

@Module({
    imports: [
        DiagnosisModule,
        DatabaseModule,
        LocalizationModule,
        TreatmentsModule,
        ValidatorsModule,
        MlModule,
    ],
    controllers: [
        DiagnosisController,
        ScansController,
        PreferencesController,
        LocalizationController,
        TreatmentsController,
    ],
})
export class ApiModule { }
