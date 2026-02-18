import { OnModuleInit } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
interface LabelLoadResult {
    isSuccess: boolean;
    error?: string;
    classCount?: number;
    crops?: Set<string>;
}
export declare class LabelLoaderService implements OnModuleInit {
    private readonly configService;
    private readonly logger;
    private indexToLabel;
    private labelToIndex;
    private isLoaded;
    private readonly EXPECTED_CLASS_COUNT;
    constructor(configService: ConfigService);
    onModuleInit(): Promise<void>;
    loadLabels(): Promise<LabelLoadResult>;
    private validateExpectedClasses;
    private extractCropList;
    getLabelByIndex(index: number): string | undefined;
    getIndexByLabel(label: string): number | undefined;
    getAllLabels(): string[];
    isLabelsLoaded(): boolean;
    getClassCount(): number;
}
export {};
