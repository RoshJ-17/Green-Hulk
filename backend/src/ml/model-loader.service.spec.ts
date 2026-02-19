import { Test, TestingModule } from "@nestjs/testing";
import { ConfigService } from "@nestjs/config";
import { ModelLoaderService } from "./model-loader.service";

// Mock fetch globally
global.fetch = jest.fn();

describe("ModelLoaderService", () => {
  let service: ModelLoaderService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ModelLoaderService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string) => {
              if (key === "TFLITE_SERVICE_URL") return "http://localhost:5000";
              return null;
            }),
          },
        },
      ],
    }).compile();

    service = module.get<ModelLoaderService>(ModelLoaderService);

    // Clear all mocks before each test
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe("checkTFLiteService", () => {
    it("should return true when TFLite service is healthy", async () => {
      const mockResponse = {
        ok: true,
        json: jest
          .fn()
          .mockResolvedValue({ status: "healthy", model: "loaded" }),
      };
      (global.fetch as jest.Mock).mockResolvedValue(mockResponse);

      const result = await service.checkTFLiteService();

      expect(result).toBe(true);
      expect(service.isModelLoaded()).toBe(true);
      expect(global.fetch).toHaveBeenCalledWith("http://localhost:5000/health");
    });

    it("should return false when TFLite service responds with error", async () => {
      const mockResponse = {
        ok: false,
        json: jest.fn().mockResolvedValue({ error: "Service unavailable" }),
      };
      (global.fetch as jest.Mock).mockResolvedValue(mockResponse);

      const result = await service.checkTFLiteService();

      expect(result).toBe(false);
      expect(service.isModelLoaded()).toBe(false);
    });

    it("should return false when fetch throws an error", async () => {
      (global.fetch as jest.Mock).mockRejectedValue(new Error("Network error"));

      const result = await service.checkTFLiteService();

      expect(result).toBe(false);
      expect(service.isModelLoaded()).toBe(false);
    });
  });

  describe("isModelLoaded", () => {
    it("should return false initially", () => {
      expect(service.isModelLoaded()).toBe(false);
    });

    it("should return true after successful health check", async () => {
      const mockResponse = {
        ok: true,
        json: jest
          .fn()
          .mockResolvedValue({ status: "healthy", model: "loaded" }),
      };
      (global.fetch as jest.Mock).mockResolvedValue(mockResponse);

      await service.checkTFLiteService();

      expect(service.isModelLoaded()).toBe(true);
    });
  });

  describe("runInference", () => {
    it("should throw error when model is not loaded", async () => {
      const input = new Float32Array(224 * 224 * 3);

      await expect(service.runInference(input)).rejects.toThrow(
        "TFLite service not available",
      );
    });

    it("should successfully run inference with valid input", async () => {
      // First, set model as loaded
      const healthResponse = {
        ok: true,
        json: jest
          .fn()
          .mockResolvedValue({ status: "healthy", model: "loaded" }),
      };
      (global.fetch as jest.Mock).mockResolvedValueOnce(healthResponse);
      await service.checkTFLiteService();

      // Mock inference response
      const mockProbabilities = new Array(38).fill(0).map(() => Math.random());
      const inferenceResponse = {
        ok: true,
        json: jest.fn().mockResolvedValue({ probabilities: mockProbabilities }),
      };
      (global.fetch as jest.Mock).mockResolvedValueOnce(inferenceResponse);

      const input = new Float32Array(224 * 224 * 3);
      const result = await service.runInference(input);

      expect(result).toEqual(mockProbabilities);
      expect(global.fetch).toHaveBeenCalledWith(
        "http://localhost:5000/predict",
        expect.objectContaining({
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: expect.any(String),
        }),
      );
    });

    it("should throw error when inference fails", async () => {
      // Set model as loaded
      const healthResponse = {
        ok: true,
        json: jest
          .fn()
          .mockResolvedValue({ status: "healthy", model: "loaded" }),
      };
      (global.fetch as jest.Mock).mockResolvedValueOnce(healthResponse);
      await service.checkTFLiteService();

      // Mock failed inference
      const errorResponse = {
        ok: false,
        json: jest.fn().mockResolvedValue({ error: "Invalid input size" }),
        statusText: "Bad Request",
      };
      (global.fetch as jest.Mock).mockResolvedValueOnce(errorResponse);

      const input = new Float32Array(224 * 224 * 3);

      await expect(service.runInference(input)).rejects.toThrow(
        "Inference failed",
      );
    });

    it("should handle network errors during inference", async () => {
      // Set model as loaded
      const healthResponse = {
        ok: true,
        json: jest
          .fn()
          .mockResolvedValue({ status: "healthy", model: "loaded" }),
      };
      (global.fetch as jest.Mock).mockResolvedValueOnce(healthResponse);
      await service.checkTFLiteService();

      // Mock network error
      (global.fetch as jest.Mock).mockRejectedValueOnce(
        new Error("Network timeout"),
      );

      const input = new Float32Array(224 * 224 * 3);

      await expect(service.runInference(input)).rejects.toThrow(
        "Inference failed",
      );
    });
  });

  describe("loadModel", () => {
    it("should call checkTFLiteService", async () => {
      const spy = jest.spyOn(service, "checkTFLiteService");
      const mockResponse = {
        ok: true,
        json: jest
          .fn()
          .mockResolvedValue({ status: "healthy", model: "loaded" }),
      };
      (global.fetch as jest.Mock).mockResolvedValue(mockResponse);

      await service.loadModel();

      expect(spy).toHaveBeenCalled();
    });
  });

  describe("dispose", () => {
    it("should set isLoaded to false", async () => {
      // First load the model
      const mockResponse = {
        ok: true,
        json: jest
          .fn()
          .mockResolvedValue({ status: "healthy", model: "loaded" }),
      };
      (global.fetch as jest.Mock).mockResolvedValue(mockResponse);
      await service.checkTFLiteService();

      expect(service.isModelLoaded()).toBe(true);

      // Dispose
      service.dispose();

      expect(service.isModelLoaded()).toBe(false);
    });
  });
});
