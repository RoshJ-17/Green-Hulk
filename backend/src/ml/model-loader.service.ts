import { Injectable, Logger, OnModuleInit } from "@nestjs/common";

@Injectable()
export class ModelLoaderService implements OnModuleInit {
  private readonly logger = new Logger(ModelLoaderService.name);
  private isLoaded = false;
  private readonly TFLITE_SERVICE_URL = "http://localhost:5000";

  private readonly EXPECTED_INPUT_SIZE = 224;
  private readonly EXPECTED_OUTPUT_CLASSES = 38;

  constructor() {}

  async onModuleInit() {
    this.logger.log("Initializing model loader...");
    this.logger.log("Using Python TFLite microservice for inference");
    await this.checkTFLiteService();
  }

  async checkTFLiteService(): Promise<boolean> {
    try {
      const response = await fetch(`${this.TFLITE_SERVICE_URL}/health`);
      if (response.ok) {
        const data = await response.json();
        this.logger.log(
          `✅ TFLite service is ${data.status} - model: ${data.model}`,
        );
        this.isLoaded = true;
        return true;
      } else {
        this.logger.warn(
          "⚠️ TFLite service not responding. Start it with: python tflite_service.py",
        );
        return false;
      }
    } catch (error) {
      this.logger.warn(
        "⚠️ TFLite service not available. Start it with: python tflite_service.py",
      );
      this.logger.warn(`Error: ${error.message}`);
      return false;
    }
  }

  isModelLoaded(): boolean {
    return this.isLoaded;
  }

  /**
   * Run inference on preprocessed image data
   * @param input Float32Array of shape [1, 224, 224, 3] = 150528 elements
   */
  async runInference(input: Float32Array): Promise<number[]> {
    if (!this.isLoaded) {
      throw new Error(
        "TFLite service not available. Please start: python tflite_service.py",
      );
    }

    try {
      // Send the preprocessed image data to the Python TFLite service
      const response = await fetch(`${this.TFLITE_SERVICE_URL}/predict`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          input: Array.from(input), // Convert Float32Array to regular array for JSON
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(
          `TFLite service error: ${error.error || response.statusText}`,
        );
      }

      const result = await response.json();
      return result.probabilities;
    } catch (error) {
      this.logger.error(`Inference failed: ${error.message}`);
      throw new Error(`Inference failed: ${error.message}`);
    }
  }

  async loadModel(): Promise<boolean> {
    return this.checkTFLiteService();
  }

  dispose() {
    this.isLoaded = false;
  }
}
