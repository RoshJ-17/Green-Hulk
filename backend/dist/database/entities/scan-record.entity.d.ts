export declare class ScanRecord {
    id: number;
    timestamp: Date;
    cropType: string;
    imagePath: string;
    diseaseName: string;
    fullLabel: string;
    confidence: number;
    severity: string;
    affectedAreaPercentage?: number;
    heatmapPath?: string;
    latitude?: number;
    longitude?: number;
    isSynced: boolean;
    lastSyncAttempt?: Date;
    imageBlurScore?: number;
    imageBrightness?: number;
    hadQualityWarnings: boolean;
}
