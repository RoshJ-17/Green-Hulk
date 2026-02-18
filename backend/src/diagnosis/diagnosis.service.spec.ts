import { Test, TestingModule } from '@nestjs/testing';
import { DiagnosisService } from './diagnosis.service';
import { ModelLoaderService } from '@ml/model-loader.service';
import { LabelLoaderService } from '@ml/label-loader.service';
import { ImageProcessorService } from '@image/image-processor.service';
import { QualityCheckerService } from '@image/quality-checker.service';
import { OodDetectorService } from '@validators/ood-detector.service';
import { CropValidatorService } from '@validators/crop-validator.service';
import { PredictionValidatorService } from '@validators/prediction-validator.service';

import sharp from 'sharp';

// Mock sharp
jest.mock('sharp');

describe('DiagnosisService', () => {
    let service: DiagnosisService;
    let modelLoader: jest.Mocked<ModelLoaderService>;
    let sharpMock: any;

    const validImageBuffer = Buffer.from([
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
        0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x64,
    ]);

    beforeEach(async () => {
        // Setup sharp mock properties
        sharpMock = {
            metadata: jest.fn().mockResolvedValue({
                width: 100,
                height: 100,
                format: 'png'
            }),
        };

        // Make sharp() return the mock object
        (sharp as unknown as jest.Mock).mockReturnValue(sharpMock);

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
                        getLabel: jest.fn().mockReturnValue('Tomato___healthy'),
                        getCropType: jest.fn().mockReturnValue('Tomato'),
                        getAllLabels: jest.fn().mockReturnValue(Array(38).fill('Tomato___healthy')),
                    },
                },
                {
                    provide: ImageProcessorService,
                    useValue: {
                        preprocess: jest.fn().mockResolvedValue(new Float32Array(224 * 224 * 3)),
                        calculateBrightness: jest.fn().mockResolvedValue(128),
                        calculateBlurScore: jest.fn().mockResolvedValue(1000),
                    },
                },
                {
                    provide: QualityCheckerService,
                    useValue: {
                        checkImageQuality: jest.fn().mockResolvedValue({
                            isGood: true,
                            hasCriticalIssues: false,
                            issues: [],
                            brightness: 128,
                            blurScore: 1000,
                        }),
                        getUserFriendlyMessage: jest.fn(),
                    },
                },
                {
                    provide: OodDetectorService,
                    useValue: {
                        analyze: jest.fn().mockReturnValue({
                            isInDistribution: true,
                        }),
                    },
                },
                {
                    provide: CropValidatorService,
                    useValue: {
                        validatePrediction: jest.fn().mockReturnValue({
                            type: 'valid',
                            disease: 'Tomato___healthy',
                            confidence: 0.95,
                            severity: 'low',
                        }),
                    },
                },
                {
                    provide: PredictionValidatorService,
                    useValue: {
                        validate: jest.fn().mockReturnValue({
                            isValid: true,
                            confidence: 0.95,
                        }),
                    },
                },
            ],
        }).compile();

        service = module.get<DiagnosisService>(DiagnosisService);
        modelLoader = module.get(ModelLoaderService) as jest.Mocked<ModelLoaderService>;
    });

    it('should be defined', () => {
        expect(service).toBeDefined();
    });

    it('should return error when model is not loaded', async () => {
        modelLoader.isModelLoaded.mockReturnValue(false);
        modelLoader.runInference.mockRejectedValue(new Error('TFLite service not available'));

        const result = await service.diagnose(validImageBuffer, 'Tomato');

        expect(result.type).toBe('error');
        if (result.type === 'error') {
            expect(result.message).toContain('failed');
        }
    });

    it('should successfully diagnose with valid input', async () => {
        modelLoader.isModelLoaded.mockReturnValue(true);
        modelLoader.runInference.mockResolvedValue(
            Array(38).fill(0.01).map((_, i) => (i === 0 ? 0.95 : 0.01))
        );

        const result = await service.diagnose(validImageBuffer, 'Tomato');

        expect(result.type).toBe('success');
        if (result.type === 'success') {
            expect(result.disease).toBe('Tomato___healthy');
            expect(result.confidence).toBe(0.95);
            expect(result.fullLabel).toBe('Tomato___healthy');
            expect(result.allProbabilities).toBeDefined();
        }
        expect(modelLoader.runInference).toHaveBeenCalled();
    });

    it('should handle invalid image buffer', async () => {
        const invalidBuffer = Buffer.from('not an image');

        const result = await service.diagnose(invalidBuffer, 'Tomato');

        expect(result.type).toBe('error');
    });
});
