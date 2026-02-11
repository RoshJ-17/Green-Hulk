/**
 * Confidence Helper
 * Tasks 2.2.1 & 2.2.3: Convert AI confidence to percentage and flag low confidence
 */
export class ConfidenceHelper {
    /**
     * Convert raw probability (0.88) to percentage string ("88%")
     * Task 2.2.1: Confidence percentage extraction
     */
    static toPercentageString(confidence: number): string {
        const percentage = Math.round(confidence * 100);
        return `${percentage}%`;
    }

    /**
     * Check if confidence is low (below 50%)
     * Task 2.2.3: Low confidence flag logic
     */
    static isLowConfidence(confidence: number): boolean {
        return confidence < 0.50;
    }

    /**
     * Get confidence level category
     * High: >= 0.80
     * Medium: 0.50 - 0.79
     * Low: < 0.50
     */
    static getConfidenceLevel(confidence: number): 'high' | 'medium' | 'low' {
        if (confidence >= 0.80) return 'high';
        if (confidence >= 0.50) return 'medium';
        return 'low';
    }

    /**
     * Get user-friendly confidence message
     */
    static getConfidenceMessage(confidence: number, language: string = 'en'): string {
        const level = this.getConfidenceLevel(confidence);

        const messages: Record<string, Record<string, string>> = {
            en: {
                high: 'High confidence diagnosis',
                medium: 'Moderate confidence - consider getting a second opinion',
                low: 'Low confidence - please retake photo with better lighting and focus',
            },
            ta: {
                high: 'உயர் நம்பகத்தன்மை நோய் கண்டறிதல்',
                medium: 'நடுத்தர நம்பகத்தன்மை - இரண்டாவது கருத்தைப் பெறுங்கள்',
                low: 'குறைந்த நம்பகத்தன்மை - சிறந்த வெளிச்சத்தில் மீண்டும் புகைப்படம் எடுக்கவும்',
            },
        };

        return messages[language]?.[level] || messages.en[level];
    }

    /**
     * Get confidence icon based on level
     */
    static getConfidenceIcon(confidence: number): string {
        const level = this.getConfidenceLevel(confidence);

        const icons = {
            high: 'check_circle',
            medium: 'warning',
            low: 'error',
        };

        return icons[level];
    }

    /**
     * Get confidence color for UI
     */
    static getConfidenceColor(confidence: number): string {
        const level = this.getConfidenceLevel(confidence);

        const colors = {
            high: '#4CAF50', // Green
            medium: '#FF9800', // Orange
            low: '#F44336', // Red
        };

        return colors[level];
    }

    /**
     * Format confidence for display with context
     */
    static formatConfidenceDisplay(confidence: number): {
        percentage: string;
        isLow: boolean;
        level: string;
        message: string;
        icon: string;
        color: string;
    } {
        return {
            percentage: this.toPercentageString(confidence),
            isLow: this.isLowConfidence(confidence),
            level: this.getConfidenceLevel(confidence),
            message: this.getConfidenceMessage(confidence),
            icon: this.getConfidenceIcon(confidence),
            color: this.getConfidenceColor(confidence),
        };
    }
}
