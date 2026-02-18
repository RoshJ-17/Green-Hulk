"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const testing_1 = require("@nestjs/testing");
const config_1 = require("@nestjs/config");
const model_loader_service_1 = require("./model-loader.service");
global.fetch = jest.fn();
describe('ModelLoaderService', () => {
    let service;
    let configService;
    beforeEach(async () => {
        const module = await testing_1.Test.createTestingModule({
            providers: [
                model_loader_service_1.ModelLoaderService,
                {
                    provide: config_1.ConfigService,
                    useValue: {
                        get: jest.fn((key) => {
                            if (key === 'TFLITE_SERVICE_URL')
                                return 'http://localhost:5000';
                            return null;
                        }),
                    },
                },
            ],
        }).compile();
        service = module.get(model_loader_service_1.ModelLoaderService);
        configService = module.get(config_1.ConfigService);
        jest.clearAllMocks();
    });
    afterEach(() => {
        jest.restoreAllMocks();
    });
    describe('checkTFLiteService', () => {
        it('should return true when TFLite service is healthy', async () => {
            const mockResponse = {
                ok: true,
                json: jest.fn().mockResolvedValue({ status: 'healthy', model: 'loaded' }),
            };
            global.fetch.mockResolvedValue(mockResponse);
            const result = await service.checkTFLiteService();
            expect(result).toBe(true);
            expect(service.isModelLoaded()).toBe(true);
            expect(global.fetch).toHaveBeenCalledWith('http://localhost:5000/health');
        });
        it('should return false when TFLite service responds with error', async () => {
            const mockResponse = {
                ok: false,
                json: jest.fn().mockResolvedValue({ error: 'Service unavailable' }),
            };
            global.fetch.mockResolvedValue(mockResponse);
            const result = await service.checkTFLiteService();
            expect(result).toBe(false);
            expect(service.isModelLoaded()).toBe(false);
        });
        it('should return false when fetch throws an error', async () => {
            global.fetch.mockRejectedValue(new Error('Network error'));
            const result = await service.checkTFLiteService();
            expect(result).toBe(false);
            expect(service.isModelLoaded()).toBe(false);
        });
    });
    describe('isModelLoaded', () => {
        it('should return false initially', () => {
            expect(service.isModelLoaded()).toBe(false);
        });
        it('should return true after successful health check', async () => {
            const mockResponse = {
                ok: true,
                json: jest.fn().mockResolvedValue({ status: 'healthy', model: 'loaded' }),
            };
            global.fetch.mockResolvedValue(mockResponse);
            await service.checkTFLiteService();
            expect(service.isModelLoaded()).toBe(true);
        });
    });
    describe('runInference', () => {
        it('should throw error when model is not loaded', async () => {
            const input = new Float32Array(224 * 224 * 3);
            await expect(service.runInference(input)).rejects.toThrow('TFLite service not available');
        });
        it('should successfully run inference with valid input', async () => {
            const healthResponse = {
                ok: true,
                json: jest.fn().mockResolvedValue({ status: 'healthy', model: 'loaded' }),
            };
            global.fetch.mockResolvedValueOnce(healthResponse);
            await service.checkTFLiteService();
            const mockProbabilities = new Array(38).fill(0).map(() => Math.random());
            const inferenceResponse = {
                ok: true,
                json: jest.fn().mockResolvedValue({ probabilities: mockProbabilities }),
            };
            global.fetch.mockResolvedValueOnce(inferenceResponse);
            const input = new Float32Array(224 * 224 * 3);
            const result = await service.runInference(input);
            expect(result).toEqual(mockProbabilities);
            expect(global.fetch).toHaveBeenCalledWith('http://localhost:5000/predict', expect.objectContaining({
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: expect.any(String),
            }));
        });
        it('should throw error when inference fails', async () => {
            const healthResponse = {
                ok: true,
                json: jest.fn().mockResolvedValue({ status: 'healthy', model: 'loaded' }),
            };
            global.fetch.mockResolvedValueOnce(healthResponse);
            await service.checkTFLiteService();
            const errorResponse = {
                ok: false,
                json: jest.fn().mockResolvedValue({ error: 'Invalid input size' }),
                statusText: 'Bad Request',
            };
            global.fetch.mockResolvedValueOnce(errorResponse);
            const input = new Float32Array(224 * 224 * 3);
            await expect(service.runInference(input)).rejects.toThrow('Inference failed');
        });
        it('should handle network errors during inference', async () => {
            const healthResponse = {
                ok: true,
                json: jest.fn().mockResolvedValue({ status: 'healthy', model: 'loaded' }),
            };
            global.fetch.mockResolvedValueOnce(healthResponse);
            await service.checkTFLiteService();
            global.fetch.mockRejectedValueOnce(new Error('Network timeout'));
            const input = new Float32Array(224 * 224 * 3);
            await expect(service.runInference(input)).rejects.toThrow('Inference failed');
        });
    });
    describe('loadModel', () => {
        it('should call checkTFLiteService', async () => {
            const spy = jest.spyOn(service, 'checkTFLiteService');
            const mockResponse = {
                ok: true,
                json: jest.fn().mockResolvedValue({ status: 'healthy', model: 'loaded' }),
            };
            global.fetch.mockResolvedValue(mockResponse);
            await service.loadModel();
            expect(spy).toHaveBeenCalled();
        });
    });
    describe('dispose', () => {
        it('should set isLoaded to false', async () => {
            const mockResponse = {
                ok: true,
                json: jest.fn().mockResolvedValue({ status: 'healthy', model: 'loaded' }),
            };
            global.fetch.mockResolvedValue(mockResponse);
            await service.checkTFLiteService();
            expect(service.isModelLoaded()).toBe(true);
            service.dispose();
            expect(service.isModelLoaded()).toBe(false);
        });
    });
});
//# sourceMappingURL=model-loader.service.spec.js.map