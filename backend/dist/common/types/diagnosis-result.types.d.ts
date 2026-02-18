export declare enum PredictionStatus {
    CONFIDENT = "confident",
    LOW_CONFIDENCE = "lowConfidence",
    UNKNOWN = "unknown"
}
export declare enum OODReason {
    LOW_MAX_PROBABILITY = "lowMaxProbability",
    HIGH_ENTROPY = "highEntropy",
    CONFLICTING_CROPS = "conflictingCrops",
    SMALL_MARGIN = "smallMargin"
}
export declare enum IssueSeverity {
    CRITICAL = "critical",
    WARNING = "warning"
}
export declare enum IssueType {
    BLUR = "blur",
    DARKNESS = "darkness",
    OVEREXPOSURE = "overexposure",
    LOW_RESOLUTION = "lowResolution"
}
export interface QualityIssue {
    type: IssueType;
    severity: IssueSeverity;
    message: string;
    suggestion: string;
}
export interface TopPrediction {
    crop: string;
    disease: string;
    probability: number;
}
export interface TopKAnalysis {
    predictions: TopPrediction[];
    isDifferentCrops: boolean;
    margin: number;
    crops: string[];
}
export type DiagnosisResult = SuccessResult | PoorQualityResult | OutOfDistributionResult | WrongCropResult | LowConfidenceResult | ErrorResult;
export interface SuccessResult {
    type: "success";
    disease: string;
    confidence: number;
    severity: string;
    cropType: string;
    fullLabel: string;
    allProbabilities: number[];
    qualityWarnings?: QualityIssue[];
}
export interface PoorQualityResult {
    type: "poorQuality";
    message: string;
    issues: QualityIssue[];
}
export interface OutOfDistributionResult {
    type: "outOfDistribution";
    message: string;
    reason: OODReason;
    maxProbability?: number;
    entropy?: number;
}
export interface WrongCropResult {
    type: "wrongCrop";
    selectedCrop: string;
    detectedCrop: string;
    message: string;
}
export interface LowConfidenceResult {
    type: "lowConfidence";
    message: string;
    confidence: number;
}
export interface ErrorResult {
    type: "error";
    message: string;
    stackTrace?: string;
}
export type ValidationResult = ValidResult | WrongCropValidation | LowQualityValidation;
export interface ValidResult {
    type: "valid";
    disease: string;
    confidence: number;
    severity: string;
}
export interface WrongCropValidation {
    type: "wrongCrop";
    selectedCrop: string;
    detectedCrop: string;
    message: string;
}
export interface LowQualityValidation {
    type: "lowQuality";
    message: string;
}
export interface OODResult {
    isInDistribution: boolean;
    reason?: OODReason;
    message?: string;
    maxProbability?: number;
    entropy?: number;
    topCandidates?: TopPrediction[];
}
export interface QualityCheckResult {
    isGood: boolean;
    issues: QualityIssue[];
    hasCriticalIssues: boolean;
}
