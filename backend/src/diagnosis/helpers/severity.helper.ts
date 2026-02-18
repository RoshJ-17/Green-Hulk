/**
 * Severity Helper
 * Tasks 2.5.3 & 2.5.4: Map severity to UI colors and urgency alerts
 */

export enum SeverityLevel {
  HEALTHY = "healthy",
  EARLY_STAGE = "early_stage",
  MODERATE = "moderate",
  SEVERE = "severe",
  CRITICAL = "critical",
}

export enum SeverityColor {
  SAFE = "green",
  EARLY_STAGE = "yellow",
  URGENT = "red",
}

export class SeverityHelper {
  /**
   * Map severity level to UI color
   * Task 2.5.3: Severity color mapping
   * Green: Safe, Yellow: Early Stage, Red: Urgency Alert
   */
  static getSeverityColor(severity: string): SeverityColor {
    const severityLower = severity.toLowerCase();

    if (severityLower === "healthy" || severityLower === "safe") {
      return SeverityColor.SAFE;
    }

    if (
      severityLower === "early_stage" ||
      severityLower === "early" ||
      severityLower === "mild" ||
      severityLower === "moderate"
    ) {
      return SeverityColor.EARLY_STAGE;
    }

    if (
      severityLower === "severe" ||
      severityLower === "critical" ||
      severityLower === "urgent"
    ) {
      return SeverityColor.URGENT;
    }

    // Default to early stage for unknown severities
    return SeverityColor.EARLY_STAGE;
  }

  /**
   * Check if urgency alert is required
   * Task 2.5.4: Urgency alert logic
   */
  static requiresUrgencyAlert(severity: string): boolean {
    const color = this.getSeverityColor(severity);
    return color === SeverityColor.URGENT;
  }

  /**
   * Get user-friendly severity message
   */
  static getSeverityMessage(severity: string, language: string = "en"): string {
    const color = this.getSeverityColor(severity);

    const messages: Record<string, Record<string, string>> = {
      en: {
        [SeverityColor.SAFE]: "Your plant appears healthy",
        [SeverityColor.EARLY_STAGE]:
          "Early stage detected - take action soon to prevent spread",
        [SeverityColor.URGENT]:
          "⚠️ URGENT: Severe infection detected - immediate treatment required!",
      },
      ta: {
        [SeverityColor.SAFE]: "உங்கள் செடி ஆரோக்கியமாக உள்ளது",
        [SeverityColor.EARLY_STAGE]:
          "ஆரம்ப நிலை கண்டறியப்பட்டது - பரவாமல் தடுக்க விரைவில் நடவடிக்கை எடுக்கவும்",
        [SeverityColor.URGENT]:
          "⚠️ அவசரம்: கடுமையான தொற்று கண்டறியப்பட்டது - உடனடி சிகிச்சை தேவை!",
      },
    };

    return messages[language]?.[color] || messages.en[color];
  }

  /**
   * Get severity icon
   */
  static getSeverityIcon(severity: string): string {
    const color = this.getSeverityColor(severity);

    const icons = {
      [SeverityColor.SAFE]: "check_circle",
      [SeverityColor.EARLY_STAGE]: "warning",
      [SeverityColor.URGENT]: "error",
    };

    return icons[color];
  }

  /**
   * Get hex color code for severity
   */
  static getSeverityHexColor(severity: string): string {
    const color = this.getSeverityColor(severity);

    const hexColors = {
      [SeverityColor.SAFE]: "#4CAF50", // Green
      [SeverityColor.EARLY_STAGE]: "#FFC107", // Yellow/Amber
      [SeverityColor.URGENT]: "#F44336", // Red
    };

    return hexColors[color];
  }

  /**
   * Get recommended action timeframe
   */
  static getActionTimeframe(severity: string): string {
    const color = this.getSeverityColor(severity);

    const timeframes = {
      [SeverityColor.SAFE]: "No immediate action needed",
      [SeverityColor.EARLY_STAGE]: "Take action within 2-3 days",
      [SeverityColor.URGENT]: "Take action immediately",
    };

    return timeframes[color];
  }

  /**
   * Determine if notification should be sent
   */
  static shouldSendNotification(severity: string): boolean {
    // Send notification for moderate and severe cases
    const color = this.getSeverityColor(severity);
    return (
      color === SeverityColor.EARLY_STAGE || color === SeverityColor.URGENT
    );
  }

  /**
   * Get notification priority
   */
  static getNotificationPriority(severity: string): "low" | "medium" | "high" {
    const color = this.getSeverityColor(severity);

    const priorities = {
      [SeverityColor.SAFE]: "low" as const,
      [SeverityColor.EARLY_STAGE]: "medium" as const,
      [SeverityColor.URGENT]: "high" as const,
    };

    return priorities[color];
  }

  /**
   * Format severity for display with all context
   */
  static formatSeverityDisplay(
    severity: string,
    language: string = "en",
  ): {
    color: SeverityColor;
    hexColor: string;
    message: string;
    icon: string;
    requiresAlert: boolean;
    timeframe: string;
    priority: string;
    shouldNotify: boolean;
  } {
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
