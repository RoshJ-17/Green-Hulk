import { Test, TestingModule } from '@nestjs/testing';
import { ImageProcessorService } from './image-processor.service';
import sharp from 'sharp';
import { ImageProcessingException } from '@common/exceptions/custom.exceptions';

// Mock sharp
jest.mock('sharp');

describe('ImageProcessorService', () => {
    let service: ImageProcessorService;
    let sharpInstance: any;

    beforeEach(async () => {
        // Setup sharp mock chain
        sharpInstance = {
            metadata: jest.fn().mockResolvedValue({ width: 1000, height: 1000, format: 'jpeg' }),
            extract: jest.fn().mockReturnThis(),
            resize: jest.fn().mockReturnThis(),
            removeAlpha: jest.fn().mockReturnThis(),
            raw: jest.fn().mockReturnThis(),
            toBuffer: jest.fn().mockResolvedValue({
                data: Buffer.alloc(224 * 224 * 3),
                info: { width: 224, height: 224, channels: 3 }
            }),
            greyscale: jest.fn().mockReturnThis(),
            normalize: jest.fn().mockReturnThis(),
        };

        (sharp as unknown as jest.Mock).mockReturnValue(sharpInstance);

        const module: TestingModule = await Test.createTestingModule({
            providers: [ImageProcessorService],
        }).compile();

        service = module.get<ImageProcessorService>(ImageProcessorService);
    });

    it('should be defined', () => {
        expect(service).toBeDefined();
    });

    describe('preprocess', () => {
        it('should successfully preprocess valid image', async () => {
            const buffer = Buffer.from('fake-image');
            const result = await service.preprocess(buffer);

            expect(result).toBeInstanceOf(Float32Array);
            expect(result.length).toBe(224 * 224 * 3);
            expect(sharp).toHaveBeenCalledWith(buffer);
            expect(sharpInstance.resize).toHaveBeenCalledWith(224, 224, expect.any(Object));
        });

        it('should throw error for invalid dimensions', async () => {
            sharpInstance.metadata.mockResolvedValue({}); // Missing width/height

            await expect(service.preprocess(Buffer.from('bad-image')))
                .rejects.toThrow(ImageProcessingException);
        });
    });

    describe('calculateBrightness', () => {
        it('should calculate brightness correctly', async () => {
            // Mock a 1x1 pixel: RGB(100, 100, 100) -> 0.299*100 + 0.587*100 + 0.114*100 = 100
            sharpInstance.toBuffer.mockResolvedValue({
                data: Buffer.from([100, 100, 100]),
                info: { width: 1, height: 1 }
            });

            const brightness = await service.calculateBrightness(Buffer.from('img'));
            expect(brightness).toBeCloseTo(100);
        });
    });

    describe('calculateBlurScore', () => {
        it('should return 0 variance for uniform image', async () => {
            sharpInstance.toBuffer.mockResolvedValue({
                data: Buffer.alloc(100, 100), // All 100s
                info: { width: 10, height: 10 }
            });

            const score = await service.calculateBlurScore(Buffer.from('img'));
            expect(score).toBe(0);
        });

        it('should return high variance for mixed image (sharp edges + flat areas)', async () => {
            // Create mixed image: half flat, half stripes
            const data = Buffer.alloc(100);
            // First 50 pixels are all 0 (flat)
            for (let i = 0; i < 50; i++) {
                data[i] = 0;
            }
            // Last 50 pixels are stripes (edges)
            for (let i = 50; i < 100; i++) {
                data[i] = i % 2 === 0 ? 0 : 255;
            }

            sharpInstance.toBuffer.mockResolvedValue({
                data: data,
                info: { width: 10, height: 10 }
            });

            const score = await service.calculateBlurScore(Buffer.from('img'));
            expect(score).toBeGreaterThan(0);
        });
    });
});
