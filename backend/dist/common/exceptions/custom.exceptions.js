"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UnsupportedCropException = exports.ImageProcessingException = exports.LabelLoadException = exports.ModelIncompatibleException = exports.ModelCorruptedException = exports.ModelNotFoundException = exports.ModelLoadException = void 0;
class ModelLoadException extends Error {
    constructor(message) {
        super(message);
        this.name = 'ModelLoadException';
    }
}
exports.ModelLoadException = ModelLoadException;
class ModelNotFoundException extends ModelLoadException {
    constructor(path) {
        super(`Model file not found at path: ${path}`);
        this.name = 'ModelNotFoundException';
    }
}
exports.ModelNotFoundException = ModelNotFoundException;
class ModelCorruptedException extends ModelLoadException {
    constructor(message) {
        super(`Model file is corrupted: ${message}`);
        this.name = 'ModelCorruptedException';
    }
}
exports.ModelCorruptedException = ModelCorruptedException;
class ModelIncompatibleException extends ModelLoadException {
    constructor(message) {
        super(`Model architecture is incompatible: ${message}`);
        this.name = 'ModelIncompatibleException';
    }
}
exports.ModelIncompatibleException = ModelIncompatibleException;
class LabelLoadException extends Error {
    constructor(message) {
        super(message);
        this.name = 'LabelLoadException';
    }
}
exports.LabelLoadException = LabelLoadException;
class ImageProcessingException extends Error {
    constructor(message) {
        super(message);
        this.name = 'ImageProcessingException';
    }
}
exports.ImageProcessingException = ImageProcessingException;
class UnsupportedCropException extends Error {
    constructor(crop, supportedCrops) {
        super(`Crop "${crop}" is not supported. Supported crops: ${supportedCrops.join(', ')}`);
        this.name = 'UnsupportedCropException';
    }
}
exports.UnsupportedCropException = UnsupportedCropException;
//# sourceMappingURL=custom.exceptions.js.map