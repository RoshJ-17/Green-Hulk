import { Injectable, Logger } from '@nestjs/common';
import sharp from 'sharp';
import { ImageProcessingException } from '@common/exceptions/custom.exceptions';

@Injectable()
export class ImageProcessorService {
    private readonly logger = new Logger(ImageProcessorService.name);
    private readonly INPUT_SIZE = 224;

    /**
     * Load image from buffer
     */
    async loadImage(buffer: Buffer): Promise<sharp.Sharp> {
        try {
            const image = sharp(buffer);
            const metadata = await image.metadata();

            if (!metadata.width || !metadata.height) {
                throw new ImageProcessingException('Invalid image: missing dimensions');
            }

            return image;
        } catch (error) {
            if (error instanceof ImageProcessingException) {
                throw error;
            }
            throw new ImageProcessingException(
                `Failed to decode image: ${error.message}`,
            );
        }
    }

    /**
     * Complete preprocessing pipeline:
     * 1. Square crop (center-based)
     * 2. Brightness normalization
     * 3. Resize to 224x224
     * 4. Convert to Float32Array with [0, 1] normalization
     */
    async preprocess(imageBuffer: Buffer): Promise<Float32Array> {
        try {
            let image = sharp(imageBuffer);

            // Step 1: Get metadata
            const metadata = await image.metadata();
            if (!metadata.width || !metadata.height) {
                throw new ImageProcessingException('Invalid image dimensions');
            }

            // Step 2: Square crop (center-based)
            const size = Math.min(metadata.width, metadata.height);
            const xOffset = Math.floor((metadata.width - size) / 2);
            const yOffset = Math.floor((metadata.height - size) / 2);

            image = image.extract({
                left: xOffset,
                top: yOffset,
                width: size,
                height: size,
            });

            // Step 3: Resize to 224x224 with cubic interpolation
            image = image.resize(this.INPUT_SIZE, this.INPUT_SIZE, {
                kernel: sharp.kernel.cubic,
            });

            // Step 5: Convert to raw RGB buffer
            const { data, info } = await image
                .removeAlpha()
                .raw()
                .toBuffer({ resolveWithObject: true });

            // Step 6: Convert to Float32Array with [0, 1] normalization
            return this.imageToFloat32Array(data, info.width, info.height);
        } catch (error) {
            if (error instanceof ImageProcessingException) {
                throw error;
            }
            throw new ImageProcessingException(
                `Preprocessing failed: ${error.message}`,
            );
        }
    }

    /**
     * Convert raw RGB buffer to Float32Array with [0, 1] normalization
     */
    private imageToFloat32Array(
        buffer: Buffer,
        width: number,
        height: number,
    ): Float32Array {
        const float32Data = new Float32Array(width * height * 3);
        let bufferIndex = 0;

        for (let i = 0; i < buffer.length; i++) {
            // Normalize to [-1, 1] range (Standard for MobileNet)
            // (pixel - 127.5) / 127.5
            float32Data[bufferIndex++] = (buffer[i] - 127.5) / 127.5;
        }

        return float32Data;
    }

    /**
     * Calculate perceived brightness of an image
     * Formula: 0.299*R + 0.587*G + 0.114*B
     */
    async calculateBrightness(imageBuffer: Buffer): Promise<number> {
        try {
            const { data, info } = await sharp(imageBuffer)
                .resize(100, 100) // Downsample for faster calculation
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
        } catch (error) {
            throw new ImageProcessingException(
                `Brightness calculation failed: ${error.message}`,
            );
        }
    }

    /**
     * Calculate blur score using Laplacian variance
     * Lower values indicate more blur
     */
    async calculateBlurScore(imageBuffer: Buffer): Promise<number> {
        try {
            // Convert to grayscale and resize for faster processing
            const { data, info } = await sharp(imageBuffer)
                .resize(200, 200)
                .greyscale()
                .raw()
                .toBuffer({ resolveWithObject: true });

            // Apply Laplacian kernel
            const laplacian = this.applyLaplacianKernel(
                data,
                info.width,
                info.height,
            );

            // Calculate variance
            return this.calculateVariance(laplacian);
        } catch (error) {
            throw new ImageProcessingException(
                `Blur calculation failed: ${error.message}`,
            );
        }
    }

    /**
     * Apply Laplacian kernel for edge detection
     * Kernel: [0, 1, 0], [1, -4, 1], [0, 1, 0]
     */
    private applyLaplacianKernel(
        data: Buffer,
        width: number,
        height: number,
    ): number[] {
        const result: number[] = [];

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

    /**
     * Calculate variance of pixel values
     */
    private calculateVariance(values: number[]): number {
        if (values.length === 0) return 0;

        const sum = values.reduce((acc, val) => acc + val, 0);
        const mean = sum / values.length;

        const sumSquared = values.reduce((acc, val) => acc + val * val, 0);
        const variance = sumSquared / values.length - mean * mean;

        return variance;
    }
}
