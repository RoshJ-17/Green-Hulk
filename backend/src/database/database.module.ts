import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { DataSource, DataSourceOptions } from "typeorm";
import { ScanRecord } from "./entities/scan-record.entity";
import { TreatmentPlan } from "./entities/treatment-plan.entity";
import { UserPreferences } from "./entities/user-preferences.entity";
import { UserPreferencesService } from "./services/user-preferences.service";
import { ScanHistoryService } from "./services/scan-history.service";
import { StorageUtilityService } from "./services/storage-utility.service";

import { User } from "./entities/user.entity";

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: "postgres",
        host: configService.get<string>("DB_HOST") || "localhost",
        port: configService.get<number>("DB_PORT") || 5432,
        username: configService.get<string>("DB_USER") || "postgres",
        password: configService.get<string>("DB_PASS") || "",
        database: configService.get<string>("DB_NAME") || "green_hulk",
        entities: [ScanRecord, TreatmentPlan, UserPreferences, User],
        synchronize: true,
        retryAttempts: 0,
        // allows the app to boot even if PostgreSQL is not yet available
        dataSourceFactory: async (options: DataSourceOptions | undefined) => {
          const ds = new DataSource(options!);
          try {
            await ds.initialize();
          } catch (err: any) {
            console.error(
              "\n⚠️  [Database] PostgreSQL unavailable: " + err.message,
            );
            console.warn(
              "⚠️  [Database] Running without DB — /auth/send-otp still works.\n",
            );
          }
          return ds;
        },
      }),
      inject: [ConfigService],
    }),
    TypeOrmModule.forFeature([
      ScanRecord,
      TreatmentPlan,
      UserPreferences,
      User,
    ]),
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
export class DatabaseModule {}
