import { Repository } from 'typeorm';
import { ScanRecord } from '@database/entities/scan-record.entity';
export declare class ScanHistoryService {
    private readonly scanRecordRepository;
    private readonly logger;
    constructor(scanRecordRepository: Repository<ScanRecord>);
    saveScanRecord(scanData: Partial<ScanRecord>): Promise<ScanRecord>;
    getScanHistory(cropType?: string, limit?: number): Promise<ScanRecord[]>;
    getRecentScans(limit?: number): Promise<ScanRecord[]>;
    getUnsyncedRecords(): Promise<ScanRecord[]>;
    markAsSynced(recordId: number): Promise<void>;
    syncScanFromMobile(scanData: Partial<ScanRecord>): Promise<ScanRecord>;
    getScanById(id: number): Promise<ScanRecord | null>;
    deleteOldScans(daysOld?: number): Promise<number>;
    getScanStats(): Promise<{
        totalScans: number;
        scansByCrop: Record<string, number>;
        recentScans: number;
    }>;
    searchByDisease(diseaseName: string): Promise<ScanRecord[]>;
}
