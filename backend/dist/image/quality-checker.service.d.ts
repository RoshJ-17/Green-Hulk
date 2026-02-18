import { ConfigService } from '@nestjs/config';
import { ImageProcessorService } from './image-processor.service';
import { QualityCheckResult } from '@common/types/diagnosis-result.types';
export declare class QualityCheckerService {
    private readonly imageProcessor;
    private readonly configService;
    private readonly logger;
    private readonly BLUR_THRESHOLD;
    private readonly MIN_BRIGHTNESS;
    private readonly MAX_BRIGHTNESS;
    private readonly MIN_RESOLUTION;
    constructor(imageProcessor: ImageProcessorService, configService: ConfigService);
    checkImageQuality(imageBuffer: Buffer, metadata: {
        width: number;
        height: number;
    }): Promise<QualityCheckResult>;
    getUserFriendlyMessage(result: QualityCheckResult): string;
}
