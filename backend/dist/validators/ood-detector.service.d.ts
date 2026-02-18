import { ConfigService } from "@nestjs/config";
import { SupportedClassesService } from "./supported-classes.service";
import { OODResult } from "@common/types/diagnosis-result.types";
export declare class OodDetectorService {
    private readonly supportedClasses;
    private readonly MAX_PROB_THRESHOLD;
    private readonly ENTROPY_THRESHOLD;
    private readonly TOP_K_MARGIN_THRESHOLD;
    constructor(supportedClasses: SupportedClassesService, configService: ConfigService);
    analyze(probabilities: number[], labels: string[]): OODResult;
    private calculateEntropy;
    private analyzeTopK;
    private formatTopK;
}
