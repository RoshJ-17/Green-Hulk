"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SeverityHelper = exports.SeverityColor = exports.SeverityLevel = void 0;
var SeverityLevel;
(function (SeverityLevel) {
    SeverityLevel["HEALTHY"] = "healthy";
    SeverityLevel["EARLY_STAGE"] = "early_stage";
    SeverityLevel["MODERATE"] = "moderate";
    SeverityLevel["SEVERE"] = "severe";
    SeverityLevel["CRITICAL"] = "critical";
})(SeverityLevel || (exports.SeverityLevel = SeverityLevel = {}));
var SeverityColor;
(function (SeverityColor) {
    SeverityColor["SAFE"] = "green";
    SeverityColor["EARLY_STAGE"] = "yellow";
    SeverityColor["URGENT"] = "red";
})(SeverityColor || (exports.SeverityColor = SeverityColor = {}));
class SeverityHelper {
    static getSeverityColor(severity) {
        const severityLower = severity.toLowerCase();
        if (severityLower === "healthy" || severityLower === "safe") {
            return SeverityColor.SAFE;
        }
        if (severityLower === "early_stage" ||
            severityLower === "early" ||
            severityLower === "mild" ||
            severityLower === "moderate") {
            return SeverityColor.EARLY_STAGE;
        }
        if (severityLower === "severe" ||
            severityLower === "critical" ||
            severityLower === "urgent") {
            return SeverityColor.URGENT;
        }
        return SeverityColor.EARLY_STAGE;
    }
    static requiresUrgencyAlert(severity) {
        const color = this.getSeverityColor(severity);
        return color === SeverityColor.URGENT;
    }
    static getSeverityMessage(severity, language = "en") {
        const color = this.getSeverityColor(severity);
        const messages = {
            en: {
                [SeverityColor.SAFE]: "Your plant appears healthy",
                [SeverityColor.EARLY_STAGE]: "Early stage detected - take action soon to prevent spread",
                [SeverityColor.URGENT]: "⚠️ URGENT: Severe infection detected - immediate treatment required!",
            },
            ta: {
                [SeverityColor.SAFE]: "உங்கள் செடி ஆரோக்கியமாக உள்ளது",
                [SeverityColor.EARLY_STAGE]: "ஆரம்ப நிலை கண்டறியப்பட்டது - பரவாமல் தடுக்க விரைவில் நடவடிக்கை எடுக்கவும்",
                [SeverityColor.URGENT]: "⚠️ அவசரம்: கடுமையான தொற்று கண்டறியப்பட்டது - உடனடி சிகிச்சை தேவை!",
            },
        };
        return messages[language]?.[color] || messages.en[color];
    }
    static getSeverityIcon(severity) {
        const color = this.getSeverityColor(severity);
        const icons = {
            [SeverityColor.SAFE]: "check_circle",
            [SeverityColor.EARLY_STAGE]: "warning",
            [SeverityColor.URGENT]: "error",
        };
        return icons[color];
    }
    static getSeverityHexColor(severity) {
        const color = this.getSeverityColor(severity);
        const hexColors = {
            [SeverityColor.SAFE]: "#4CAF50",
            [SeverityColor.EARLY_STAGE]: "#FFC107",
            [SeverityColor.URGENT]: "#F44336",
        };
        return hexColors[color];
    }
    static getActionTimeframe(severity) {
        const color = this.getSeverityColor(severity);
        const timeframes = {
            [SeverityColor.SAFE]: "No immediate action needed",
            [SeverityColor.EARLY_STAGE]: "Take action within 2-3 days",
            [SeverityColor.URGENT]: "Take action immediately",
        };
        return timeframes[color];
    }
    static shouldSendNotification(severity) {
        const color = this.getSeverityColor(severity);
        return (color === SeverityColor.EARLY_STAGE || color === SeverityColor.URGENT);
    }
    static getNotificationPriority(severity) {
        const color = this.getSeverityColor(severity);
        const priorities = {
            [SeverityColor.SAFE]: "low",
            [SeverityColor.EARLY_STAGE]: "medium",
            [SeverityColor.URGENT]: "high",
        };
        return priorities[color];
    }
    static formatSeverityDisplay(severity, language = "en") {
        return {
            color: this.getSeverityColor(severity),
            hexColor: this.getSeverityHexColor(severity),
            message: this.getSeverityMessage(severity, language),
            icon: this.getSeverityIcon(severity),
            requiresAlert: this.requiresUrgencyAlert(severity),
            timeframe: this.getActionTimeframe(severity),
            priority: this.getNotificationPriority(severity),
            shouldNotify: this.shouldSendNotification(severity),
        };
    }
}
exports.SeverityHelper = SeverityHelper;
//# sourceMappingURL=severity.helper.js.map