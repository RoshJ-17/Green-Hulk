"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.IssueType = exports.IssueSeverity = exports.OODReason = exports.PredictionStatus = void 0;
var PredictionStatus;
(function (PredictionStatus) {
    PredictionStatus["CONFIDENT"] = "confident";
    PredictionStatus["LOW_CONFIDENCE"] = "lowConfidence";
    PredictionStatus["UNKNOWN"] = "unknown";
})(PredictionStatus || (exports.PredictionStatus = PredictionStatus = {}));
var OODReason;
(function (OODReason) {
    OODReason["LOW_MAX_PROBABILITY"] = "lowMaxProbability";
    OODReason["HIGH_ENTROPY"] = "highEntropy";
    OODReason["CONFLICTING_CROPS"] = "conflictingCrops";
    OODReason["SMALL_MARGIN"] = "smallMargin";
})(OODReason || (exports.OODReason = OODReason = {}));
var IssueSeverity;
(function (IssueSeverity) {
    IssueSeverity["CRITICAL"] = "critical";
    IssueSeverity["WARNING"] = "warning";
})(IssueSeverity || (exports.IssueSeverity = IssueSeverity = {}));
var IssueType;
(function (IssueType) {
    IssueType["BLUR"] = "blur";
    IssueType["DARKNESS"] = "darkness";
    IssueType["OVEREXPOSURE"] = "overexposure";
    IssueType["LOW_RESOLUTION"] = "lowResolution";
})(IssueType || (exports.IssueType = IssueType = {}));
//# sourceMappingURL=diagnosis-result.types.js.map