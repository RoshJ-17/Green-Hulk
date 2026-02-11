export declare class StorageUtilityService {
    private readonly logger;
    private readonly dataDirectory;
    constructor();
    calculateDirectorySize(dirPath: string): Promise<number>;
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
    private countFiles;
    private getStorageBreakdown;
    private formatBytes;
    cleanupOldFiles(daysOld?: number): Promise<{
        filesDeleted: number;
        spaceFreed: number;
    }>;
    isStorageLow(limitMB?: number): Promise<boolean>;
    getStorageUsagePercent(limitMB?: number): Promise<number>;
}
