import { ScanHistoryService } from '@database/services/scan-history.service';
import { StorageUtilityService } from '@database/services/storage-utility.service';
import { ScanRecord } from '@database/entities/scan-record.entity';
export declare class ScansController {
    private readonly scanHistoryService;
    private readonly storageService;
    constructor(scanHistoryService: ScanHistoryService, storageService: StorageUtilityService);
    getScanHistory(cropType?: string, limit?: number): Promise<ScanRecord[]>;
    getRecentScans(limit?: number): Promise<ScanRecord[]>;
    syncScan(scanData: Partial<ScanRecord>): Promise<ScanRecord>;
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
    getScanStats(): Promise<{
        totalScans: number;
        scansByCrop: Record<string, number>;
        recentScans: number;
    }>;
    searchByDisease(disease: string): Promise<ScanRecord[]>;
}
