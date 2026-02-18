"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var LabelLoaderService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.LabelLoaderService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const fs = __importStar(require("fs/promises"));
const path = __importStar(require("path"));
const custom_exceptions_1 = require("../common/exceptions/custom.exceptions");
let LabelLoaderService = LabelLoaderService_1 = class LabelLoaderService {
    constructor(configService) {
        this.configService = configService;
        this.logger = new common_1.Logger(LabelLoaderService_1.name);
        this.indexToLabel = new Map();
        this.labelToIndex = new Map();
        this.isLoaded = false;
        this.EXPECTED_CLASS_COUNT = 38;
    }
    async onModuleInit() {
        this.logger.log("Initializing label loader...");
        const result = await this.loadLabels();
        if (!result.isSuccess) {
            this.logger.warn(`Labels not loaded: ${result.error}`);
            this.logger.warn("Server will start without label mapping capability");
            return;
        }
        this.logger.log(`Labels loaded successfully: ${result.classCount} classes, ${result.crops?.size} crops`);
    }
    async loadLabels() {
        try {
            const labelsPath = this.configService.get("LABELS_PATH");
            if (!labelsPath) {
                throw new custom_exceptions_1.LabelLoadException("LABELS_PATH not configured");
            }
            const resolvedPath = path.resolve(labelsPath);
            const jsonString = await fs.readFile(resolvedPath, "utf-8");
            const jsonData = JSON.parse(jsonString);
            const classCount = Object.keys(jsonData).length;
            if (classCount !== this.EXPECTED_CLASS_COUNT) {
                throw new custom_exceptions_1.LabelLoadException(`Expected ${this.EXPECTED_CLASS_COUNT} classes, found ${classCount}`);
            }
            this.indexToLabel.clear();
            this.labelToIndex.clear();
            const seenIndices = new Set();
            const seenLabels = new Set();
            for (const [label, index] of Object.entries(jsonData)) {
                if (typeof index !== "number") {
                    throw new custom_exceptions_1.LabelLoadException(`Class "${label}" has non-integer index: ${index}`);
                }
                if (seenIndices.has(index)) {
                    throw new custom_exceptions_1.LabelLoadException(`Duplicate class index found: ${index}`);
                }
                if (seenLabels.has(label)) {
                    throw new custom_exceptions_1.LabelLoadException(`Duplicate class label found: "${label}"`);
                }
                seenIndices.add(index);
                seenLabels.add(label);
                this.labelToIndex.set(label, index);
                this.indexToLabel.set(index, label);
            }
            for (let i = 0; i < this.EXPECTED_CLASS_COUNT; i++) {
                if (!this.indexToLabel.has(i)) {
                    throw new custom_exceptions_1.LabelLoadException(`Missing class index: ${i}. Indices must be continuous from 0 to ${this.EXPECTED_CLASS_COUNT - 1}`);
                }
            }
            this.validateExpectedClasses();
            const crops = this.extractCropList();
            this.isLoaded = true;
            return {
                isSuccess: true,
                classCount: this.indexToLabel.size,
                crops,
            };
        }
        catch (error) {
            if (error instanceof custom_exceptions_1.LabelLoadException) {
                return {
                    isSuccess: false,
                    error: error.message,
                };
            }
            if (error instanceof SyntaxError) {
                return {
                    isSuccess: false,
                    error: `Invalid JSON format: ${error.message}`,
                };
            }
            return {
                isSuccess: false,
                error: `Unexpected error: ${error.message}`,
            };
        }
    }
    validateExpectedClasses() {
        const expectedSamples = [
            "Apple___Apple_scab",
            "Tomato___healthy",
            "Potato___Late_blight",
            "Corn_(maize)___Common_rust_",
        ];
        const missing = [];
        for (const expected of expectedSamples) {
            if (!this.labelToIndex.has(expected)) {
                missing.push(expected);
            }
        }
        if (missing.length > 0) {
            throw new custom_exceptions_1.LabelLoadException(`Missing expected PlantVillage classes: ${missing.join(", ")}. This may be a different dataset.`);
        }
        const invalidLabels = Array.from(this.labelToIndex.keys()).filter((label) => !label.includes("___"));
        if (invalidLabels.length > 0) {
            throw new custom_exceptions_1.LabelLoadException(`Invalid label format (missing "___" separator): ${invalidLabels.slice(0, 3).join(", ")}`);
        }
    }
    extractCropList() {
        const crops = new Set();
        for (const label of this.labelToIndex.keys()) {
            const crop = label.split("___")[0];
            const normalized = crop.split(/[,_(]/)[0].trim();
            crops.add(normalized);
        }
        return crops;
    }
    getLabelByIndex(index) {
        return this.indexToLabel.get(index);
    }
    getIndexByLabel(label) {
        return this.labelToIndex.get(label);
    }
    getAllLabels() {
        const labels = [];
        for (let i = 0; i < this.indexToLabel.size; i++) {
            const label = this.indexToLabel.get(i);
            if (label) {
                labels.push(label);
            }
        }
        return labels;
    }
    isLabelsLoaded() {
        return this.isLoaded;
    }
    getClassCount() {
        return this.indexToLabel.size;
    }
};
exports.LabelLoaderService = LabelLoaderService;
exports.LabelLoaderService = LabelLoaderService = LabelLoaderService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], LabelLoaderService);
//# sourceMappingURL=label-loader.service.js.map