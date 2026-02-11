"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var ImageProcessorService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ImageProcessorService = void 0;
const common_1 = require("@nestjs/common");
const sharp_1 = __importDefault(require("sharp"));
const custom_exceptions_1 = require("../common/exceptions/custom.exceptions");
let ImageProcessorService = ImageProcessorService_1 = class ImageProcessorService {
    constructor() {
        this.logger = new common_1.Logger(ImageProcessorService_1.name);
        this.INPUT_SIZE = 224;
    }
    async loadImage(buffer) {
        try {
            const image = (0, sharp_1.default)(buffer);
            const metadata = await image.metadata();
            if (!metadata.width || !metadata.height) {
                throw new custom_exceptions_1.ImageProcessingException('Invalid image: missing dimensions');
            }
            return image;
        }
        catch (error) {
            if (error instanceof custom_exceptions_1.ImageProcessingException) {
                throw error;
            }
            throw new custom_exceptions_1.ImageProcessingException(`Failed to decode image: ${error.message}`);
        }
    }
    async preprocess(imageBuffer) {
        try {
            let image = (0, sharp_1.default)(imageBuffer);
            const metadata = await image.metadata();
            if (!metadata.width || !metadata.height) {
                throw new custom_exceptions_1.ImageProcessingException('Invalid image dimensions');
            }
            const size = Math.min(metadata.width, metadata.height);
            const xOffset = Math.floor((metadata.width - size) / 2);
            const yOffset = Math.floor((metadata.height - size) / 2);
            image = image.extract({
                left: xOffset,
                top: yOffset,
                width: size,
                height: size,
            });
            image = image.normalize();
            image = image.resize(this.INPUT_SIZE, this.INPUT_SIZE, {
                kernel: sharp_1.default.kernel.cubic,
            });
            const { data, info } = await image
                .removeAlpha()
                .raw()
                .toBuffer({ resolveWithObject: true });
            return this.imageToFloat32Array(data, info.width, info.height);
        }
        catch (error) {
            if (error instanceof custom_exceptions_1.ImageProcessingException) {
                throw error;
            }
            throw new custom_exceptions_1.ImageProcessingException(`Preprocessing failed: ${error.message}`);
        }
    }
    imageToFloat32Array(buffer, width, height) {
        const float32Data = new Float32Array(width * height * 3);
        let bufferIndex = 0;
        for (let i = 0; i < buffer.length; i++) {
            float32Data[bufferIndex++] = buffer[i] / 255.0;
        }
        return float32Data;
    }
    async calculateBrightness(imageBuffer) {
        try {
            const { data, info } = await (0, sharp_1.default)(imageBuffer)
                .resize(100, 100)
                .removeAlpha()
                .raw()
                .toBuffer({ resolveWithObject: true });
            let totalBrightness = 0;
            const pixelCount = info.width * info.height;
            for (let i = 0; i < data.length; i += 3) {
                const r = data[i];
                const g = data[i + 1];
                const b = data[i + 2];
                const brightness = 0.299 * r + 0.587 * g + 0.114 * b;
                totalBrightness += brightness;
            }
            return totalBrightness / pixelCount;
        }
        catch (error) {
            throw new custom_exceptions_1.ImageProcessingException(`Brightness calculation failed: ${error.message}`);
        }
    }
    async calculateBlurScore(imageBuffer) {
        try {
            const { data, info } = await (0, sharp_1.default)(imageBuffer)
                .resize(200, 200)
                .greyscale()
                .raw()
                .toBuffer({ resolveWithObject: true });
            const laplacian = this.applyLaplacianKernel(data, info.width, info.height);
            return this.calculateVariance(laplacian);
        }
        catch (error) {
            throw new custom_exceptions_1.ImageProcessingException(`Blur calculation failed: ${error.message}`);
        }
    }
    applyLaplacianKernel(data, width, height) {
        const result = [];
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                const center = data[y * width + x];
                const top = data[(y - 1) * width + x];
                const bottom = data[(y + 1) * width + x];
                const left = data[y * width + (x - 1)];
                const right = data[y * width + (x + 1)];
                const value = Math.abs(top + bottom + left + right - 4 * center);
                result.push(value);
            }
        }
        return result;
    }
    calculateVariance(values) {
        if (values.length === 0)
            return 0;
        const sum = values.reduce((acc, val) => acc + val, 0);
        const mean = sum / values.length;
        const sumSquared = values.reduce((acc, val) => acc + val * val, 0);
        const variance = sumSquared / values.length - mean * mean;
        return variance;
    }
};
exports.ImageProcessorService = ImageProcessorService;
exports.ImageProcessorService = ImageProcessorService = ImageProcessorService_1 = __decorate([
    (0, common_1.Injectable)()
], ImageProcessorService);
//# sourceMappingURL=image-processor.service.js.map