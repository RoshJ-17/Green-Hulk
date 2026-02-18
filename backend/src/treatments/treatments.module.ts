import { Module } from "@nestjs/common";
import { TreatmentsService } from "./treatments.service";

@Module({
  providers: [TreatmentsService],
  exports: [TreatmentsService],
})
export class TreatmentsModule {}
