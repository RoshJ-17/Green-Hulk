import { Module } from "@nestjs/common";
import { ImageProcessorService } from "./image-processor.service";
import { QualityCheckerService } from "./quality-checker.service";

@Module({
  providers: [ImageProcessorService, QualityCheckerService],
  exports: [ImageProcessorService, QualityCheckerService],
})
export class ImageModule {}
