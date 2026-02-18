import { Test, TestingModule } from "@nestjs/testing";
import { BadRequestException } from "@nestjs/common";
import { getRepositoryToken } from "@nestjs/typeorm";
import { DiagnosisController } from "./diagnosis.controller";
import { DiagnosisService } from "@diagnosis/diagnosis.service";
import { SupportedClassesService } from "@validators/supported-classes.service";
import { LabelLoaderService } from "@ml/label-loader.service";
import { ScanRecord } from "@database/entities/scan-record.entity";

describe("DiagnosisController", () => {
  let controller: DiagnosisController;
  let diagnosisService: jest.Mocked<DiagnosisService>;
  let supportedClasses: jest.Mocked<SupportedClassesService>;

  const mockFile: Express.Multer.File = {
    fieldname: "image",
    originalname: "test-plant.jpg",
    encoding: "7bit",
    mimetype: "image/jpeg",
    size: 50000,
    buffer: Buffer.from("fake image data"),
    stream: null as any,
    destination: "",
    filename: "",
    path: "",
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [DiagnosisController],
      providers: [
        {
          provide: DiagnosisService,
          useValue: {
            diagnose: jest.fn(),
          },
        },
        {
          provide: SupportedClassesService,
          useValue: {
            isCropSupported: jest.fn(),
            getSupportedCrops: jest
              .fn()
              .mockReturnValue(["Tomato", "Potato", "Corn"]),
          },
        },
        {
          provide: LabelLoaderService,
          useValue: {
            getLabel: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(ScanRecord),
          useValue: {
            create: jest.fn().mockImplementation((dto) => dto),
            save: jest.fn().mockResolvedValue({}),
            find: jest.fn(),
            findOne: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<DiagnosisController>(DiagnosisController);
    diagnosisService = module.get(
      DiagnosisService,
    ) as jest.Mocked<DiagnosisService>;
    supportedClasses = module.get(
      SupportedClassesService,
    ) as jest.Mocked<SupportedClassesService>;
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });

  it("should successfully diagnose with valid input", async () => {
    const dto = { selectedCrop: "Tomato" };
    supportedClasses.isCropSupported.mockReturnValue(true);
    diagnosisService.diagnose.mockResolvedValue({
      type: "success",
      disease: "Tomato___Late_blight",
      confidence: 0.92,
      severity: "high",
      cropType: "Tomato",
      fullLabel: "Tomato___Late_blight",
      allProbabilities: new Array(38).fill(0),
    });

    const result = await controller.diagnose(mockFile, dto);

    expect(result.type).toBe("success");
    expect(diagnosisService.diagnose).toHaveBeenCalledWith(
      mockFile.buffer,
      "Tomato",
    );
  });

  it("should throw BadRequestException when file is missing", async () => {
    const dto = { selectedCrop: "Tomato" };

    await expect(controller.diagnose(null as any, dto)).rejects.toThrow(
      BadRequestException,
    );
  });

  it("should throw BadRequestException for unsupported crop", async () => {
    const dto = { selectedCrop: "Banana" };
    supportedClasses.isCropSupported.mockReturnValue(false);

    await expect(controller.diagnose(mockFile, dto)).rejects.toThrow(
      BadRequestException,
    );
  });

  it("should handle diagnosis errors", async () => {
    const dto = { selectedCrop: "Tomato" };
    supportedClasses.isCropSupported.mockReturnValue(true);
    diagnosisService.diagnose.mockResolvedValue({
      type: "poorQuality",
      message: "Poor image quality",
      issues: [],
    });

    const result = await controller.diagnose(mockFile, dto);

    expect(result.type).toBe("poorQuality");
    expect(result.message).toBe("Poor image quality");
  });
});
