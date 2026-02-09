import { Injectable, Logger } from '@nestjs/common';
import * as fs from 'fs/promises';
import * as path from 'path';

/**
 * Utility service for storage management
 * Task 4.4.4: Calculate size of local data folder and report to UI
 */
@Injectable()
export class StorageUtilityService {
    private readonly logger = new Logger(StorageUtilityService.name);
    private readonly dataDirectory: string;

    constructor() {
        // Default data directory - can be configured via environment variable
        this.dataDirectory = process.env.DATA_DIR || path.join(process.cwd(), 'data');
    }

    /**
     * Calculate the total size of a directory recursively
     * Task 4.4.4: Storage check implementation
     */
    async calculateDirectorySize(dirPath: string): Promise<number> {
        let totalSize = 0;

        try {
            const stats = await fs.stat(dirPath);

            if (stats.isFile()) {
                return stats.size;
            }

            if (stats.isDirectory()) {
                const files = await fs.readdir(dirPath);

                for (const file of files) {
                    const filePath = path.join(dirPath, file);
                    const fileSize = await this.calculateDirectorySize(filePath);
                    totalSize += fileSize;
                }
            }
        } catch (error) {
            this.logger.warn(`Error calculating size for ${dirPath}: ${error.message}`);
        }

        return totalSize;
    }

    /**
     * Get storage information for the data directory
     * Task 4.4.4: Report storage info to FE1
     */
    async getStorageInfo(): Promise<{
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
    }> {
        this.logger.debug('Calculating storage information...');

        const totalSizeBytes = await this.calculateDirectorySize(this.dataDirectory);
        const fileCount = await this.countFiles(this.dataDirectory);

        // Calculate breakdown by type
        const breakdown = await this.getStorageBreakdown();

        const totalSizeMB = totalSizeBytes / (1024 * 1024);
        const totalSizeReadable = this.formatBytes(totalSizeBytes);

        this.logger.log(
            `Storage info: ${totalSizeReadable} across ${fileCount} files`,
        );

        return {
            totalSizeBytes,
            totalSizeMB: parseFloat(totalSizeMB.toFixed(2)),
            totalSizeReadable,
            fileCount,
            directoryPath: this.dataDirectory,
            breakdown,
        };
    }

    /**
     * Count total number of files in directory
     */
    private async countFiles(dirPath: string): Promise<number> {
        let count = 0;

        try {
            const stats = await fs.stat(dirPath);

            if (stats.isFile()) {
                return 1;
            }

            if (stats.isDirectory()) {
                const files = await fs.readdir(dirPath);

                for (const file of files) {
                    const filePath = path.join(dirPath, file);
                    count += await this.countFiles(filePath);
                }
            }
        } catch (error) {
            this.logger.warn(`Error counting files in ${dirPath}: ${error.message}`);
        }

        return count;
    }

    /**
     * Get storage breakdown by file type
     */
    private async getStorageBreakdown(): Promise<{
        images: number;
        database: number;
        audio: number;
        other: number;
    }> {
        const breakdown = {
            images: 0,
            database: 0,
            audio: 0,
            other: 0,
        };

        try {
            // Check images directory
            const imagesPath = path.join(this.dataDirectory, 'images');
            breakdown.images = await this.calculateDirectorySize(imagesPath);

            // Check database files
            const dbPath = path.join(this.dataDirectory, 'database.sqlite');
            try {
                const dbStats = await fs.stat(dbPath);
                breakdown.database = dbStats.size;
            } catch {
                // Database file might not exist yet
            }

            // Check audio files
            const audioPath = path.join(this.dataDirectory, 'audio');
            breakdown.audio = await this.calculateDirectorySize(audioPath);

            // Other files
            const totalSize = await this.calculateDirectorySize(this.dataDirectory);
            breakdown.other = totalSize - (breakdown.images + breakdown.database + breakdown.audio);
        } catch (error) {
            this.logger.warn(`Error calculating storage breakdown: ${error.message}`);
        }

        return breakdown;
    }

    /**
     * Format bytes to human-readable string
     */
    private formatBytes(bytes: number): string {
        if (bytes === 0) return '0 Bytes';

        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));

        return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`;
    }

    /**
     * Clean up old files based on age
     */
    async cleanupOldFiles(daysOld: number = 90): Promise<{
        filesDeleted: number;
        spaceFreed: number;
    }> {
        this.logger.log(`Cleaning up files older than ${daysOld} days...`);

        const cutoffDate = Date.now() - daysOld * 24 * 60 * 60 * 1000;
        let filesDeleted = 0;
        let spaceFreed = 0;

        const imagesPath = path.join(this.dataDirectory, 'images');

        try {
            const files = await fs.readdir(imagesPath);

            for (const file of files) {
                const filePath = path.join(imagesPath, file);
                const stats = await fs.stat(filePath);

                if (stats.mtimeMs < cutoffDate) {
                    spaceFreed += stats.size;
                    await fs.unlink(filePath);
                    filesDeleted++;
                }
            }
        } catch (error) {
            this.logger.error(`Error during cleanup: ${error.message}`);
        }

        this.logger.log(
            `Cleanup complete: ${filesDeleted} files deleted, ${this.formatBytes(spaceFreed)} freed`,
        );

        return {
            filesDeleted,
            spaceFreed,
        };
    }

    /**
     * Check if storage is running low (above 80% of limit)
     */
    async isStorageLow(limitMB: number = 500): Promise<boolean> {
        const storageInfo = await this.getStorageInfo();
        const limitBytes = limitMB * 1024 * 1024;
        const usagePercent = (storageInfo.totalSizeBytes / limitBytes) * 100;

        return usagePercent > 80;
    }

    /**
     * Get storage usage percentage
     */
    async getStorageUsagePercent(limitMB: number = 500): Promise<number> {
        const storageInfo = await this.getStorageInfo();
        const limitBytes = limitMB * 1024 * 1024;
        const usagePercent = (storageInfo.totalSizeBytes / limitBytes) * 100;

        return parseFloat(usagePercent.toFixed(2));
    }
}
