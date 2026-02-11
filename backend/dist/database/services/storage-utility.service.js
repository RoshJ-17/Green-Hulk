"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var StorageUtilityService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.StorageUtilityService = void 0;
const common_1 = require("@nestjs/common");
const fs = __importStar(require("fs/promises"));
const path = __importStar(require("path"));
let StorageUtilityService = StorageUtilityService_1 = class StorageUtilityService {
    constructor() {
        this.logger = new common_1.Logger(StorageUtilityService_1.name);
        this.dataDirectory = process.env.DATA_DIR || path.join(process.cwd(), 'data');
    }
    async calculateDirectorySize(dirPath) {
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
        }
        catch (error) {
            this.logger.warn(`Error calculating size for ${dirPath}: ${error.message}`);
        }
        return totalSize;
    }
    async getStorageInfo() {
        this.logger.debug('Calculating storage information...');
        const totalSizeBytes = await this.calculateDirectorySize(this.dataDirectory);
        const fileCount = await this.countFiles(this.dataDirectory);
        const breakdown = await this.getStorageBreakdown();
        const totalSizeMB = totalSizeBytes / (1024 * 1024);
        const totalSizeReadable = this.formatBytes(totalSizeBytes);
        this.logger.log(`Storage info: ${totalSizeReadable} across ${fileCount} files`);
        return {
            totalSizeBytes,
            totalSizeMB: parseFloat(totalSizeMB.toFixed(2)),
            totalSizeReadable,
            fileCount,
            directoryPath: this.dataDirectory,
            breakdown,
        };
    }
    async countFiles(dirPath) {
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
        }
        catch (error) {
            this.logger.warn(`Error counting files in ${dirPath}: ${error.message}`);
        }
        return count;
    }
    async getStorageBreakdown() {
        const breakdown = {
            images: 0,
            database: 0,
            audio: 0,
            other: 0,
        };
        try {
            const imagesPath = path.join(this.dataDirectory, 'images');
            breakdown.images = await this.calculateDirectorySize(imagesPath);
            const dbPath = path.join(this.dataDirectory, 'database.sqlite');
            try {
                const dbStats = await fs.stat(dbPath);
                breakdown.database = dbStats.size;
            }
            catch {
            }
            const audioPath = path.join(this.dataDirectory, 'audio');
            breakdown.audio = await this.calculateDirectorySize(audioPath);
            const totalSize = await this.calculateDirectorySize(this.dataDirectory);
            breakdown.other = totalSize - (breakdown.images + breakdown.database + breakdown.audio);
        }
        catch (error) {
            this.logger.warn(`Error calculating storage breakdown: ${error.message}`);
        }
        return breakdown;
    }
    formatBytes(bytes) {
        if (bytes === 0)
            return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`;
    }
    async cleanupOldFiles(daysOld = 90) {
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
        }
        catch (error) {
            this.logger.error(`Error during cleanup: ${error.message}`);
        }
        this.logger.log(`Cleanup complete: ${filesDeleted} files deleted, ${this.formatBytes(spaceFreed)} freed`);
        return {
            filesDeleted,
            spaceFreed,
        };
    }
    async isStorageLow(limitMB = 500) {
        const storageInfo = await this.getStorageInfo();
        const limitBytes = limitMB * 1024 * 1024;
        const usagePercent = (storageInfo.totalSizeBytes / limitBytes) * 100;
        return usagePercent > 80;
    }
    async getStorageUsagePercent(limitMB = 500) {
        const storageInfo = await this.getStorageInfo();
        const limitBytes = limitMB * 1024 * 1024;
        const usagePercent = (storageInfo.totalSizeBytes / limitBytes) * 100;
        return parseFloat(usagePercent.toFixed(2));
    }
};
exports.StorageUtilityService = StorageUtilityService;
exports.StorageUtilityService = StorageUtilityService = StorageUtilityService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [])
], StorageUtilityService);
//# sourceMappingURL=storage-utility.service.js.map