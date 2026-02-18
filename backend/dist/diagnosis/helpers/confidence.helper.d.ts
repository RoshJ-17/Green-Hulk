export declare class ConfidenceHelper {
    static toPercentageString(confidence: number): string;
    static isLowConfidence(confidence: number): boolean;
    static getConfidenceLevel(confidence: number): "high" | "medium" | "low";
    static getConfidenceMessage(confidence: number, language?: string): string;
    static getConfidenceIcon(confidence: number): string;
    static getConfidenceColor(confidence: number): string;
    static formatConfidenceDisplay(confidence: number): {
        percentage: string;
        isLow: boolean;
        level: string;
        message: string;
        icon: string;
        color: string;
    };
}
