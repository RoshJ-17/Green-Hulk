import { Test, TestingModule } from "@nestjs/testing";
import { DiagnosisService } from "./diagnosis.service";
import { ModelLoaderService } from "@ml/model-loader.service";
import { LabelLoaderService } from "@ml/label-loader.service";
import { ImageProcessorService } from "@image/image-processor.service";
import { QualityCheckerService } from "@image/quality-checker.service";
import { OodDetectorService } from "@validators/ood-detector.service";
import { CropValidatorService } from "@validators/crop-validator.service";
import { PredictionValidatorService } from "@validators/prediction-validator.service";

jest.mock("sharp", () => {
  return jest.fn(() => ({
    metadata: jest
      .fn()
      .mockResolvedValue({ width: 800, height: 600, format: "jpeg" }),
    resize: jest.fn().mockReturnThis(),
    toBuffer: jest.fn().mockResolvedValue(Buffer.from("fake-pixel-data")),
  }));
});

describe("DiagnosisService", () => {
  let service: DiagnosisService;
  let modelLoader: jest.Mocked<ModelLoaderService>;

  const validImageBuffer = Buffer.from([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x64,
  ]);

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DiagnosisService,
        {
          provide: ModelLoaderService,
          useValue: {
            isModelLoaded: jest.fn(),
            runInference: jest.fn(),
          },
        },
        {
          provide: LabelLoaderService,
          useValue: {
            getLabelByIndex: jest.fn().mockReturnValue("Tomato___healthy"),
            getCropType: jest.fn().mockReturnValue("Tomato"),
            getAllLabels: jest.fn().mockReturnValue(
              Array(38)
                .fill("")
                .map((_, i) => (i === 0 ? "Tomato___healthy" : `Disease_${i}`)),
            ),
          },
        },
        {
          provide: ImageProcessorService,
          useValue: {
            preprocess: jest
              .fn()
              .mockResolvedValue(new Float32Array(224 * 224 * 3)),
            calculateBrightness: jest.fn().mockResolvedValue(128),
            calculateBlurScore: jest.fn().mockResolvedValue(1000),
          },
        },
        {
          provide: QualityCheckerService,
          useValue: {
            checkImageQuality: jest.fn().mockResolvedValue({
              isGood: true,
              issues: [],
              hasCriticalIssues: false,
            }),
            getUserFriendlyMessage: jest.fn().mockReturnValue("Quality OK"),
          },
        },
        {
          provide: OodDetectorService,
          useValue: {
            analyze: jest.fn().mockReturnValue({
              isInDistribution: true,
              maxProbability: 0.95,
              entropy: 0.1,
            }),
          },
        },
        {
          provide: CropValidatorService,
          useValue: {
            validatePrediction: jest.fn().mockReturnValue({
              type: "valid",
              disease: "healthy",
              confidence: 0.95,
              severity: "none",
            }),
          },
        },
        {
          provide: PredictionValidatorService,
          useValue: {
            validatePrediction: jest.fn().mockReturnValue({
              isValid: true,
              confidence: 0.95,
            }),
          },
        },
      ],
    }).compile();

    service = module.get<DiagnosisService>(DiagnosisService);
    modelLoader = module.get(
      ModelLoaderService,
    ) as jest.Mocked<ModelLoaderService>;
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  it("should return error when model is not loaded", async () => {
    modelLoader.isModelLoaded.mockReturnValue(false);

    const result = await service.diagnose(validImageBuffer, "Tomato");

    expect(result.type).toBe("error");
    expect((result as any).message).toContain("not loaded");
  });

  it("should successfully diagnose with valid input", async () => {
    modelLoader.isModelLoaded.mockReturnValue(true);
    modelLoader.runInference.mockResolvedValue(
      Array(38)
        .fill(0.01)
        .map((_, i) => (i === 0 ? 0.95 : 0.01)),
    );

    const result = await service.diagnose(validImageBuffer, "Tomato");

    expect(result.type).toBe("success");
    if (result.type === "success") {
      expect(result.disease).toBe("healthy");
      expect(result.confidence).toBe(0.95);
    }
    expect(modelLoader.runInference).toHaveBeenCalled();
  });

  it("should handle invalid image buffer", async () => {
    const invalidBuffer = Buffer.from("not an image");

    const result = await service.diagnose(invalidBuffer, "Tomato");

    expect(result.type).toBe("error");
  });
});
