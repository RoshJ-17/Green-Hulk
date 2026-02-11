"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var ScanHistoryService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ScanHistoryService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const scan_record_entity_1 = require("../entities/scan-record.entity");
let ScanHistoryService = ScanHistoryService_1 = class ScanHistoryService {
    constructor(scanRecordRepository) {
        this.scanRecordRepository = scanRecordRepository;
        this.logger = new common_1.Logger(ScanHistoryService_1.name);
    }
    async saveScanRecord(scanData) {
        this.logger.debug('Saving scan record...');
        const scanRecord = this.scanRecordRepository.create({
            ...scanData,
            timestamp: new Date(),
            isSynced: false,
        });
        const saved = await this.scanRecordRepository.save(scanRecord);
        this.logger.log(`Scan record saved: ID ${saved.id}, Disease: ${saved.diseaseName}, Confidence: ${saved.confidence}`);
        return saved;
    }
    async getScanHistory(cropType, limit = 50) {
        const query = this.scanRecordRepository.createQueryBuilder('scan');
        if (cropType) {
            query.where('scan.cropType = :cropType', { cropType });
        }
        return query
            .orderBy('scan.timestamp', 'DESC')
            .limit(limit)
            .getMany();
    }
    async getRecentScans(limit = 10) {
        return this.scanRecordRepository.find({
            order: { timestamp: 'DESC' },
            take: limit,
        });
    }
    async getUnsyncedRecords() {
        return this.scanRecordRepository.find({
            where: { isSynced: false },
            order: { timestamp: 'ASC' },
        });
    }
    async markAsSynced(recordId) {
        await this.scanRecordRepository.update(recordId, {
            isSynced: true,
            lastSyncAttempt: new Date(),
        });
        this.logger.debug(`Record ${recordId} marked as synced`);
    }
    async syncScanFromMobile(scanData) {
        const scanRecord = this.scanRecordRepository.create({
            ...scanData,
            isSynced: true,
            lastSyncAttempt: new Date(),
        });
        return this.scanRecordRepository.save(scanRecord);
    }
    async getScanById(id) {
        return this.scanRecordRepository.findOne({ where: { id } });
    }
    async deleteOldScans(daysOld = 90) {
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - daysOld);
        const result = await this.scanRecordRepository.delete({
            timestamp: (0, typeorm_2.LessThan)(cutoffDate),
        });
        const deletedCount = result.affected || 0;
        this.logger.log(`Deleted ${deletedCount} scan records older than ${daysOld} days`);
        return deletedCount;
    }
    async getScanStats() {
        const [totalScans, recentScans] = await Promise.all([
            this.scanRecordRepository.count(),
            this.scanRecordRepository.count({
                where: {
                    timestamp: (0, typeorm_2.LessThan)(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)),
                },
            }),
        ]);
        const cropCounts = await this.scanRecordRepository
            .createQueryBuilder('scan')
            .select('scan.cropType', 'crop')
            .addSelect('COUNT(*)', 'count')
            .groupBy('scan.cropType')
            .getRawMany();
        const scansByCrop = {};
        cropCounts.forEach((row) => {
            scansByCrop[row.crop] = parseInt(row.count, 10);
        });
        return {
            totalScans,
            scansByCrop,
            recentScans,
        };
    }
    async searchByDisease(diseaseName) {
        return this.scanRecordRepository
            .createQueryBuilder('scan')
            .where('scan.diseaseName LIKE :disease', {
            disease: `%${diseaseName}%`,
        })
            .orderBy('scan.timestamp', 'DESC')
            .getMany();
    }
};
exports.ScanHistoryService = ScanHistoryService;
exports.ScanHistoryService = ScanHistoryService = ScanHistoryService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(scan_record_entity_1.ScanRecord)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], ScanHistoryService);
//# sourceMappingURL=scan-history.service.js.map