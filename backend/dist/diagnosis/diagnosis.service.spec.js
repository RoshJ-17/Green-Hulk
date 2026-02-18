"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const testing_1 = require("@nestjs/testing");
const diagnosis_service_1 = require("./diagnosis.service");
const model_loader_service_1 = require("../ml/model-loader.service");
const label_loader_service_1 = require("../ml/label-loader.service");
const image_processor_service_1 = require("../image/image-processor.service");
const quality_checker_service_1 = require("../image/quality-checker.service");
const ood_detector_service_1 = require("../validators/ood-detector.service");
const crop_validator_service_1 = require("../validators/crop-validator.service");
const prediction_validator_service_1 = require("../validators/prediction-validator.service");
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
    let service;
    let modelLoader;
    const validImageBuffer = Buffer.from([
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x64,
    ]);
    beforeEach(async () => {
        const module = await testing_1.Test.createTestingModule({
            providers: [
                diagnosis_service_1.DiagnosisService,
                {
                    provide: model_loader_service_1.ModelLoaderService,
                    useValue: {
                        isModelLoaded: jest.fn(),
                        runInference: jest.fn(),
                    },
                },
                {
                    provide: label_loader_service_1.LabelLoaderService,
                    useValue: {
                        getLabelByIndex: jest.fn().mockReturnValue("Tomato___healthy"),
                        getCropType: jest.fn().mockReturnValue("Tomato"),
                        getAllLabels: jest.fn().mockReturnValue(Array(38)
                            .fill("")
                            .map((_, i) => (i === 0 ? "Tomato___healthy" : `Disease_${i}`))),
                    },
                },
                {
                    provide: image_processor_service_1.ImageProcessorService,
                    useValue: {
                        preprocess: jest
                            .fn()
                            .mockResolvedValue(new Float32Array(224 * 224 * 3)),
                        calculateBrightness: jest.fn().mockResolvedValue(128),
                        calculateBlurScore: jest.fn().mockResolvedValue(1000),
                    },
                },
                {
                    provide: quality_checker_service_1.QualityCheckerService,
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
                    provide: ood_detector_service_1.OodDetectorService,
                    useValue: {
                        analyze: jest.fn().mockReturnValue({
                            isInDistribution: true,
                            maxProbability: 0.95,
                            entropy: 0.1,
                        }),
                    },
                },
                {
                    provide: crop_validator_service_1.CropValidatorService,
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
                    provide: prediction_validator_service_1.PredictionValidatorService,
                    useValue: {
                        validatePrediction: jest.fn().mockReturnValue({
                            isValid: true,
                            confidence: 0.95,
                        }),
                    },
                },
            ],
        }).compile();
        service = module.get(diagnosis_service_1.DiagnosisService);
        modelLoader = module.get(model_loader_service_1.ModelLoaderService);
    });
    it("should be defined", () => {
        expect(service).toBeDefined();
    });
    it("should return error when model is not loaded", async () => {
        modelLoader.isModelLoaded.mockReturnValue(false);
        const result = await service.diagnose(validImageBuffer, "Tomato");
        expect(result.type).toBe("error");
        expect(result.message).toContain("not loaded");
    });
    it("should successfully diagnose with valid input", async () => {
        modelLoader.isModelLoaded.mockReturnValue(true);
        modelLoader.runInference.mockResolvedValue(Array(38)
            .fill(0.01)
            .map((_, i) => (i === 0 ? 0.95 : 0.01)));
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
//# sourceMappingURL=diagnosis.service.spec.js.map