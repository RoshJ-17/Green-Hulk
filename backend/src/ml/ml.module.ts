import { Module } from "@nestjs/common";
import { ModelLoaderService } from "./model-loader.service";
import { LabelLoaderService } from "./label-loader.service";

/**
 * ML Module - Architecture Note
 *
 * This module is NOT used for production inference in the current architecture.
 * The Green Hulk platform uses a mobile-first design where:
 * - Flutter app performs ML inference using TensorFlow Lite (on-device)
 * - Backend provides data services only (treatments, localization, sync)
 *
 * These services are kept for potential future use cases like:
 * - Web-based diagnosis interface
 * - Server-side validation of mobile results
 * - Analytics and model performance monitoring
 *
 * See: MODEL_FORMAT_GUIDE.md for full architecture details
 */
@Module({
  providers: [ModelLoaderService, LabelLoaderService],
  exports: [ModelLoaderService, LabelLoaderService],
})
export class MlModule {}
