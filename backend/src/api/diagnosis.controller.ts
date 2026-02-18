import {
  Controller,
  Post,
  Body,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
  Get,
  Param,
  Logger,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import {
  ApiTags,
  ApiOperation,
  ApiConsumes,
  ApiResponse,
} from "@nestjs/swagger";
import { DiagnosisService } from "@diagnosis/diagnosis.service";
import { SupportedClassesService } from "@validators/supported-classes.service";
import { LabelLoaderService } from "@ml/label-loader.service";
import { DiagnoseRequestDto } from "@common/dtos/diagnose-request.dto";
import { DiagnosisResponseDto } from "@common/dtos/diagnosis-response.dto";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { ScanRecord } from "@database/entities/scan-record.entity";

@ApiTags("diagnosis")
@Controller("api")
export class DiagnosisController {
  private readonly logger = new Logger(DiagnosisController.name);

  constructor(
    private readonly diagnosisService: DiagnosisService,
    private readonly supportedClasses: SupportedClassesService,
    private readonly labelLoader: LabelLoaderService,
    @InjectRepository(ScanRecord)
    private readonly scanRepository: Repository<ScanRecord>,
  ) {}

  @Post("diagnose")
  @ApiOperation({ summary: "Diagnose plant disease from image" })
  @ApiConsumes("multipart/form-data")
  @ApiResponse({
    status: 200,
    description: "Diagnosis completed",
    type: DiagnosisResponseDto,
  })
  @UseInterceptors(FileInterceptor("image"))
  async diagnose(
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: DiagnoseRequestDto,
  ): Promise<DiagnosisResponseDto> {
    if (!file) {
      throw new BadRequestException("Image file is required");
    }

    // Validate file size (10MB max)
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
      throw new BadRequestException("Image file too large (max 10MB)");
    }

    // Validate file type
    const allowedTypes = ["image/jpeg", "image/jpg", "image/png"];
    if (!allowedTypes.includes(file.mimetype)) {
      throw new BadRequestException("Invalid file type. Allowed: JPEG, PNG");
    }

    // Validate crop
    if (!this.supportedClasses.isCropSupported(dto.selectedCrop)) {
      throw new BadRequestException(
        `Unsupported crop: ${dto.selectedCrop}. Supported crops: ${this.supportedClasses.getSupportedCrops().join(", ")}`,
      );
    }

    this.logger.log(
      `Diagnosing ${file.originalname} for crop: ${dto.selectedCrop}`,
    );

    // Run diagnosis
    const result = await this.diagnosisService.diagnose(
      file.buffer,
      dto.selectedCrop,
    );

    // Save successful diagnoses to database
    if (result.type === "success") {
      const scanRecord = this.scanRepository.create({
        cropType: result.cropType,
        imagePath: file.originalname,
        diseaseName: result.disease,
        fullLabel: result.fullLabel,
        confidence: result.confidence,
        severity: result.severity,
        hadQualityWarnings: result.qualityWarnings !== undefined,
      });

      await this.scanRepository.save(scanRecord);
      this.logger.log(`Scan record saved: ID ${scanRecord.id}`);
    }

    return DiagnosisResponseDto.fromDiagnosisResult(result);
  }

  @Get("crops")
  @ApiOperation({ summary: "Get list of supported crops" })
  @ApiResponse({
    status: 200,
    description: "List of supported crops with disease counts",
  })
  getSupportedCrops() {
    return {
      crops: this.supportedClasses.getSupportedCrops(),
      statistics: this.supportedClasses.getCropStatistics(),
    };
  }

  @Get("diseases/:crop")
  @ApiOperation({ summary: "Get diseases for a specific crop" })
  @ApiResponse({
    status: 200,
    description: "List of diseases for the crop",
  })
  getDiseasesForCrop(@Param("crop") crop: string) {
    if (!this.supportedClasses.isCropSupported(crop)) {
      throw new BadRequestException(`Unsupported crop: ${crop}`);
    }

    const allLabels = this.labelLoader.getAllLabels();
    const diseases = this.supportedClasses.getDiseasesForCrop(crop, allLabels);

    return {
      crop,
      diseases,
      count: diseases.length,
    };
  }
}
