"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConfidenceHelper = void 0;
class ConfidenceHelper {
    static toPercentageString(confidence) {
        const percentage = Math.round(confidence * 100);
        return `${percentage}%`;
    }
    static isLowConfidence(confidence) {
        return confidence < 0.50;
    }
    static getConfidenceLevel(confidence) {
        if (confidence >= 0.80)
            return 'high';
        if (confidence >= 0.50)
            return 'medium';
        return 'low';
    }
    static getConfidenceMessage(confidence, language = 'en') {
        const level = this.getConfidenceLevel(confidence);
        const messages = {
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
    static getConfidenceIcon(confidence) {
        const level = this.getConfidenceLevel(confidence);
        const icons = {
            high: 'check_circle',
            medium: 'warning',
            low: 'error',
        };
        return icons[level];
    }
    static getConfidenceColor(confidence) {
        const level = this.getConfidenceLevel(confidence);
        const colors = {
            high: '#4CAF50',
            medium: '#FF9800',
            low: '#F44336',
        };
        return colors[level];
    }
    static formatConfidenceDisplay(confidence) {
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
exports.ConfidenceHelper = ConfidenceHelper;
//# sourceMappingURL=confidence.helper.js.map