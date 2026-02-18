import { UserPreferencesService } from "@database/services/user-preferences.service";
import { StorageUtilityService } from "@database/services/storage-utility.service";
export declare class PreferencesController {
    private readonly preferencesService;
    private readonly storageService;
    constructor(preferencesService: UserPreferencesService, storageService: StorageUtilityService);
    getUserPreferences(userId: number): Promise<import("../database/entities/user-preferences.entity").UserPreferences | null>;
    saveLastCrop(userId: number, cropId: string): Promise<import("../database/entities/user-preferences.entity").UserPreferences>;
    getLastCrop(userId: number): Promise<{
        cropId: string | null;
    }>;
    saveLanguage(userId: number, language: string): Promise<import("../database/entities/user-preferences.entity").UserPreferences>;
    setOrganicPreference(userId: number, preferOrganic: boolean): Promise<import("../database/entities/user-preferences.entity").UserPreferences>;
    getStorageInfo(): Promise<{
        totalSizeBytes: number;
        totalSizeMB: number;
        totalSizeReadable: string;
        fileCount: number;
        directoryPath: string;
        breakdown: {
            images: number;
            database: number;
            audio: number;
            other: number;
        };
    }>;
}
