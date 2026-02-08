import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ApiModule } from './api/api.module';
import { DatabaseModule } from './database/database.module';
import { DiagnosisModule } from './diagnosis/diagnosis.module';
import { MlModule } from './ml/ml.module';
import { ImageModule } from './image/image.module';
import { ValidatorsModule } from './validators/validators.module';

@Module({
    imports: [
        ConfigModule.forRoot({
            isGlobal: true,
            envFilePath: '.env',
        }),
        DatabaseModule,
        MlModule,
        ImageModule,
        ValidatorsModule,
        DiagnosisModule,
        ApiModule,
    ],
})
export class AppModule { }
