export declare class ModelLoadException extends Error {
    constructor(message: string);
}
export declare class ModelNotFoundException extends ModelLoadException {
    constructor(path: string);
}
export declare class ModelCorruptedException extends ModelLoadException {
    constructor(message: string);
}
export declare class ModelIncompatibleException extends ModelLoadException {
    constructor(message: string);
}
export declare class LabelLoadException extends Error {
    constructor(message: string);
}
export declare class ImageProcessingException extends Error {
    constructor(message: string);
}
export declare class UnsupportedCropException extends Error {
    constructor(crop: string, supportedCrops: string[]);
}
