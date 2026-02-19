import { Module } from "@nestjs/common";
import { SupportedClassesService } from "./supported-classes.service";
import { PredictionValidatorService } from "./prediction-validator.service";
import { CropValidatorService } from "./crop-validator.service";
import { OodDetectorService } from "./ood-detector.service";

@Module({
  providers: [
    SupportedClassesService,
    PredictionValidatorService,
    CropValidatorService,
    OodDetectorService,
  ],
  exports: [
    SupportedClassesService,
    PredictionValidatorService,
    CropValidatorService,
    OodDetectorService,
  ],
})
export class ValidatorsModule {}
