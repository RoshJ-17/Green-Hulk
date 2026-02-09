import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ScanRecord } from './entities/scan-record.entity';
import { TreatmentPlan } from './entities/treatment-plan.entity';
import { UserPreferences } from './entities/user-preferences.entity';
import { UserPreferencesService } from './services/user-preferences.service';
import { ScanHistoryService } from './services/scan-history.service';
import { StorageUtilityService } from './services/storage-utility.service';

@Module({
    imports: [
        TypeOrmModule.forRootAsync({
            imports: [ConfigModule],
            useFactory: (configService: ConfigService) => ({
                type: 'sqlite',
                database: configService.get<string>('DB_PATH') || './data/plant-disease.db',
                entities: [ScanRecord, TreatmentPlan, UserPreferences],
                synchronize: true, // Auto-create tables (disable in production)
                logging: configService.get<string>('NODE_ENV') === 'development',
            }),
            inject: [ConfigService],
        }),
        TypeOrmModule.forFeature([ScanRecord, TreatmentPlan, UserPreferences]),
    ],
    providers: [
        UserPreferencesService,
        ScanHistoryService,
        StorageUtilityService,
    ],
    exports: [
        TypeOrmModule,
        UserPreferencesService,
        ScanHistoryService,
        StorageUtilityService,
    ],
})
export class DatabaseModule { }
