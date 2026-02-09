import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { ScanRecord } from '@database/entities/scan-record.entity';

/**
 * Service for managing scan history
 * Task 2.7.4: Local Saving - Save scan results with timestamp, disease result, and image path
 */
@Injectable()
export class ScanHistoryService {
    private readonly logger = new Logger(ScanHistoryService.name);

    constructor(
        @InjectRepository(ScanRecord)
        private readonly scanRecordRepository: Repository<ScanRecord>,
    ) { }

    /**
     * Save a scan record to the database
     * Task 2.7.4: Store timestamp, disease result from BE1, and file path
     */
    async saveScanRecord(
        scanData: Partial<ScanRecord>,
    ): Promise<ScanRecord> {
        this.logger.debug('Saving scan record...');

        const scanRecord = this.scanRecordRepository.create({
            ...scanData,
            timestamp: new Date(),
            isSynced: false, // Mark as not synced initially
        });

        const saved = await this.scanRecordRepository.save(scanRecord);

        this.logger.log(
            `Scan record saved: ID ${saved.id}, Disease: ${saved.diseaseName}, Confidence: ${saved.confidence}`,
        );

        return saved;
    }

    /**
     * Get scan history for a specific crop type
     */
    async getScanHistory(
        cropType?: string,
        limit: number = 50,
    ): Promise<ScanRecord[]> {
        const query = this.scanRecordRepository.createQueryBuilder('scan');

        if (cropType) {
            query.where('scan.cropType = :cropType', { cropType });
        }

        return query
            .orderBy('scan.timestamp', 'DESC')
            .limit(limit)
            .getMany();
    }

    /**
     * Get recent scans (last N records)
     */
    async getRecentScans(limit: number = 10): Promise<ScanRecord[]> {
        return this.scanRecordRepository.find({
            order: { timestamp: 'DESC' },
            take: limit,
        });
    }

    /**
     * Get unsynced records (for syncing from mobile app)
     */
    async getUnsyncedRecords(): Promise<ScanRecord[]> {
        return this.scanRecordRepository.find({
            where: { isSynced: false },
            order: { timestamp: 'ASC' },
        });
    }

    /**
     * Mark a record as synced
     */
    async markAsSynced(recordId: number): Promise<void> {
        await this.scanRecordRepository.update(recordId, {
            isSynced: true,
            lastSyncAttempt: new Date(),
        });
        this.logger.debug(`Record ${recordId} marked as synced`);
    }

    /**
     * Save scan record from mobile sync
     */
    async syncScanFromMobile(scanData: Partial<ScanRecord>): Promise<ScanRecord> {
        const scanRecord = this.scanRecordRepository.create({
            ...scanData,
            isSynced: true, // Already synced since it's coming from mobile
            lastSyncAttempt: new Date(),
        });

        return this.scanRecordRepository.save(scanRecord);
    }

    /**
     * Get scan record by ID
     */
    async getScanById(id: number): Promise<ScanRecord | null> {
        return this.scanRecordRepository.findOne({ where: { id } });
    }

    /**
     * Delete old scan records (cleanup utility)
     */
    async deleteOldScans(daysOld: number = 90): Promise<number> {
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - daysOld);

        const result = await this.scanRecordRepository.delete({
            timestamp: LessThan(cutoffDate),
        });

        const deletedCount = result.affected || 0;
        this.logger.log(`Deleted ${deletedCount} scan records older than ${daysOld} days`);

        return deletedCount;
    }

    /**
     * Get scan statistics
     */
    async getScanStats(): Promise<{
        totalScans: number;
        scansByCrop: Record<string, number>;
        recentScans: number;
    }> {
        const [totalScans, recentScans] = await Promise.all([
            this.scanRecordRepository.count(),
            this.scanRecordRepository.count({
                where: {
                    timestamp: LessThan(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)),
                },
            }),
        ]);

        // Get scans grouped by crop
        const cropCounts = await this.scanRecordRepository
            .createQueryBuilder('scan')
            .select('scan.cropType', 'crop')
            .addSelect('COUNT(*)', 'count')
            .groupBy('scan.cropType')
            .getRawMany();

        const scansByCrop: Record<string, number> = {};
        cropCounts.forEach((row) => {
            scansByCrop[row.crop] = parseInt(row.count, 10);
        });

        return {
            totalScans,
            scansByCrop,
            recentScans,
        };
    }

    /**
     * Search scans by disease name
     */
    async searchByDisease(diseaseName: string): Promise<ScanRecord[]> {
        return this.scanRecordRepository
            .createQueryBuilder('scan')
            .where('scan.diseaseName LIKE :disease', {
                disease: `%${diseaseName}%`,
            })
            .orderBy('scan.timestamp', 'DESC')
            .getMany();
    }
}
