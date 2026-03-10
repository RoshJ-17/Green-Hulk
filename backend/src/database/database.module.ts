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
      useFactory: (configService: ConfigService) => {
        const databaseUrl = configService.get<string>("DATABASE_URL");
        const entities = [ScanRecord, TreatmentPlan, UserPreferences, User];

        const dataSourceFactory = async (options: DataSourceOptions | undefined) => {
          const ds = new DataSource(options!);
          try {
            await ds.initialize();
          } catch (err: any) {
            console.error("\n⚠️  [Database] PostgreSQL unavailable: " + err.message);
            console.warn("⚠️  [Database] Running without DB — scan history and auth disabled.\n");
          }
          return ds;
        };

        // Railway injects DATABASE_URL automatically when a Postgres plugin is linked.
        // Fall back to individual DB_* vars for local development.
        if (databaseUrl) {
          return {
            type: "postgres" as const,
            url: databaseUrl,
            ssl: { rejectUnauthorized: false },
            entities,
            synchronize: true,
            retryAttempts: 1,   // must be > 0 or NestJS TypeORM ignores the value
            retryDelay: 500,
            connectTimeoutMS: 3000,
            dataSourceFactory,
          };
        }

        return {
          type: "postgres" as const,
          host: configService.get<string>("DB_HOST") || "localhost",
          port: configService.get<number>("DB_PORT") || 5432,
          username: configService.get<string>("DB_USER") || "postgres",
          password: configService.get<string>("DB_PASS") || "",
          database: configService.get<string>("DB_NAME") || "green_hulk",
          entities,
          synchronize: true,
          retryAttempts: 1,   // must be > 0 or NestJS TypeORM ignores the value
          retryDelay: 500,
          connectTimeoutMS: 3000,
          dataSourceFactory,
        };
      },
      inject: [ConfigService],
    }),
    TypeOrmModule.forFeature([ScanRecord, TreatmentPlan, UserPreferences, User]),
  ],
  providers: [UserPreferencesService, ScanHistoryService, StorageUtilityService],
  exports: [TypeOrmModule, UserPreferencesService, ScanHistoryService, StorageUtilityService],
})
export class DatabaseModule {}
