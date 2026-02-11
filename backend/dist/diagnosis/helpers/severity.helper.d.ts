export declare enum SeverityLevel {
    HEALTHY = "healthy",
    EARLY_STAGE = "early_stage",
    MODERATE = "moderate",
    SEVERE = "severe",
    CRITICAL = "critical"
}
export declare enum SeverityColor {
    SAFE = "green",
    EARLY_STAGE = "yellow",
    URGENT = "red"
}
export declare class SeverityHelper {
    static getSeverityColor(severity: string): SeverityColor;
    static requiresUrgencyAlert(severity: string): boolean;
    static getSeverityMessage(severity: string, language?: string): string;
    static getSeverityIcon(severity: string): string;
    static getSeverityHexColor(severity: string): string;
    static getActionTimeframe(severity: string): string;
    static shouldSendNotification(severity: string): boolean;
    static getNotificationPriority(severity: string): 'low' | 'medium' | 'high';
    static formatSeverityDisplay(severity: string, language?: string): {
        color: SeverityColor;
        hexColor: string;
        message: string;
        icon: string;
        requiresAlert: boolean;
        timeframe: string;
        priority: string;
        shouldNotify: boolean;
    };
}
