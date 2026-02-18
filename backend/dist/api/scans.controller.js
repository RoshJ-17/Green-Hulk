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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ScansController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const scan_history_service_1 = require("../database/services/scan-history.service");
const storage_utility_service_1 = require("../database/services/storage-utility.service");
let ScansController = class ScansController {
    constructor(scanHistoryService, storageService) {
        this.scanHistoryService = scanHistoryService;
        this.storageService = storageService;
    }
    async getScanHistory(cropType, limit = 50) {
        return this.scanHistoryService.getScanHistory(cropType, limit);
    }
    async getRecentScans(limit = 10) {
        return this.scanHistoryService.getRecentScans(limit);
    }
    async syncScan(scanData) {
        return this.scanHistoryService.syncScanFromMobile(scanData);
    }
    async getStorageInfo() {
        return this.storageService.getStorageInfo();
    }
    async getScanStats() {
        return this.scanHistoryService.getScanStats();
    }
    async searchByDisease(disease) {
        return this.scanHistoryService.searchByDisease(disease);
    }
};
exports.ScansController = ScansController;
__decorate([
    (0, common_1.Get)('history'),
    (0, swagger_1.ApiOperation)({ summary: 'Get scan history' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Returns scan history' }),
    __param(0, (0, common_1.Query)('cropType')),
    __param(1, (0, common_1.Query)('limit', common_1.ParseIntPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Number]),
    __metadata("design:returntype", Promise)
], ScansController.prototype, "getScanHistory", null);
__decorate([
    (0, common_1.Get)('recent'),
    (0, swagger_1.ApiOperation)({ summary: 'Get recent scans' }),
    __param(0, (0, common_1.Query)('limit', common_1.ParseIntPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", Promise)
], ScansController.prototype, "getRecentScans", null);
__decorate([
    (0, common_1.Post)('sync'),
    (0, swagger_1.ApiOperation)({ summary: 'Sync scan record from mobile' }),
    (0, swagger_1.ApiResponse)({ status: 201, description: 'Scan synced successfully' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ScansController.prototype, "syncScan", null);
__decorate([
    (0, common_1.Get)('storage-info'),
    (0, swagger_1.ApiOperation)({ summary: 'Get storage information' }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Returns storage size and file count',
    }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ScansController.prototype, "getStorageInfo", null);
__decorate([
    (0, common_1.Get)('stats'),
    (0, swagger_1.ApiOperation)({ summary: 'Get scan statistics' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ScansController.prototype, "getScanStats", null);
__decorate([
    (0, common_1.Get)('search'),
    (0, swagger_1.ApiOperation)({ summary: 'Search scans by disease name' }),
    __param(0, (0, common_1.Query)('disease')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ScansController.prototype, "searchByDisease", null);
exports.ScansController = ScansController = __decorate([
    (0, swagger_1.ApiTags)('Scans'),
    (0, common_1.Controller)('api/scans'),
    __metadata("design:paramtypes", [scan_history_service_1.ScanHistoryService,
        storage_utility_service_1.StorageUtilityService])
], ScansController);
//# sourceMappingURL=scans.controller.js.map