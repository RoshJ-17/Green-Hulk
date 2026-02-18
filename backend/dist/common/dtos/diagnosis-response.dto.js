"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DiagnosisResponseDto = void 0;
const swagger_1 = require("@nestjs/swagger");
class DiagnosisResponseDto {
    static fromDiagnosisResult(result) {
        const dto = new DiagnosisResponseDto();
        dto.type = result.type;
        switch (result.type) {
            case "success":
                dto.disease = result.disease;
                dto.confidence = result.confidence;
                dto.severity = result.severity;
                dto.cropType = result.cropType;
                dto.fullLabel = result.fullLabel;
                break;
            case "poorQuality":
            case "outOfDistribution":
            case "lowConfidence":
            case "error":
                dto.message = result.message;
                break;
            case "wrongCrop":
                dto.selectedCrop = result.selectedCrop;
                dto.detectedCrop = result.detectedCrop;
                dto.message = result.message;
                break;
        }
        return dto;
    }
}
exports.DiagnosisResponseDto = DiagnosisResponseDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: "Type of result",
        enum: [
            "success",
            "poorQuality",
            "outOfDistribution",
            "wrongCrop",
            "lowConfidence",
            "error",
        ],
    }),
    __metadata("design:type", String)
], DiagnosisResponseDto.prototype, "type", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: "Disease name (if successful)", required: false }),
    __metadata("design:type", String)
], DiagnosisResponseDto.prototype, "disease", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: "Confidence score 0-1", required: false }),
    __metadata("design:type", Number)
], DiagnosisResponseDto.prototype, "confidence", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: "Severity level", required: false }),
    __metadata("design:type", String)
], DiagnosisResponseDto.prototype, "severity", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: "Crop type", required: false }),
    __metadata("design:type", String)
], DiagnosisResponseDto.prototype, "cropType", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: "Full label from model", required: false }),
    __metadata("design:type", String)
], DiagnosisResponseDto.prototype, "fullLabel", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: "Error or info message", required: false }),
    __metadata("design:type", String)
], DiagnosisResponseDto.prototype, "message", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: "Selected crop (for mismatch)", required: false }),
    __metadata("design:type", String)
], DiagnosisResponseDto.prototype, "selectedCrop", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: "Detected crop (for mismatch)", required: false }),
    __metadata("design:type", String)
], DiagnosisResponseDto.prototype, "detectedCrop", void 0);
//# sourceMappingURL=diagnosis-response.dto.js.map