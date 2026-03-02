import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  ParseIntPipe,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiResponse } from "@nestjs/swagger";
import { ScanHistoryService } from "@database/services/scan-history.service";
import { StorageUtilityService } from "@database/services/storage-utility.service";
import { ScanRecord } from "@database/entities/scan-record.entity";

/**
 * Scans Controller
 * Task 2.7.4: Scan history API endpoints
 */
@ApiTags("Scans")
@Controller("api/scans")
export class ScansController {
  constructor(
    private readonly scanHistoryService: ScanHistoryService,
    private readonly storageService: StorageUtilityService,
  ) {}

  /**
   * Get scan history
   * Task 2.7.4: Retrieve scan history
   */
  @Get("history")
  @ApiOperation({ summary: "Get scan history" })
  @ApiResponse({ status: 200, description: "Returns scan history" })
  async getScanHistory(
    @Query("cropType") cropType?: string,
    @Query("limit", ParseIntPipe) limit: number = 50,
  ) {
    return this.scanHistoryService.getScanHistory(cropType, limit);
  }

  /**
   * Get recent scans
   */
  @Get("recent")
  @ApiOperation({ summary: "Get recent scans" })
  async getRecentScans(@Query("limit", ParseIntPipe) limit: number = 10) {
    return this.scanHistoryService.getRecentScans(limit);
  }

  /**
   * Sync scan from mobile device
   * Task 2.7.4: Sync endpoint for offline scans
   */
  @Post("sync")
  @ApiOperation({ summary: "Sync scan record from mobile" })
  @ApiResponse({ status: 201, description: "Scan synced successfully" })
  async syncScan(@Body() scanData: Partial<ScanRecord>) {
    return this.scanHistoryService.syncScanFromMobile(scanData);
  }

  /**
   * Get storage information
   * Task 4.4.4: Storage check
   */
  @Get("storage-info")
  @ApiOperation({ summary: "Get storage information" })
  @ApiResponse({
    status: 200,
    description: "Returns storage size and file count",
  })
  async getStorageInfo() {
    return this.storageService.getStorageInfo();
  }

  /**
   * Get scan statistics
   */
  @Get("stats")
  @ApiOperation({ summary: "Get scan statistics" })
  async getScanStats() {
    return this.scanHistoryService.getScanStats();
  }

  /**
   * Search scans by disease
   */
  @Get("search")
  @ApiOperation({ summary: "Search scans by disease name" })
  async searchByDisease(@Query("disease") disease: string) {
    return this.scanHistoryService.searchByDisease(disease);
  }
}
