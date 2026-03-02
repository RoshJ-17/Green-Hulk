// Custom exceptions for better error handling

export class ModelLoadException extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ModelLoadException";
  }
}

export class ModelNotFoundException extends ModelLoadException {
  constructor(path: string) {
    super(`Model file not found at path: ${path}`);
    this.name = "ModelNotFoundException";
  }
}

export class ModelCorruptedException extends ModelLoadException {
  constructor(message: string) {
    super(`Model file is corrupted: ${message}`);
    this.name = "ModelCorruptedException";
  }
}

export class ModelIncompatibleException extends ModelLoadException {
  constructor(message: string) {
    super(`Model architecture is incompatible: ${message}`);
    this.name = "ModelIncompatibleException";
  }
}

export class LabelLoadException extends Error {
  constructor(message: string) {
    super(message);
    this.name = "LabelLoadException";
  }
}

export class ImageProcessingException extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ImageProcessingException";
  }
}

export class UnsupportedCropException extends Error {
  constructor(crop: string, supportedCrops: string[]) {
    super(
      `Crop "${crop}" is not supported. Supported crops: ${supportedCrops.join(", ")}`,
    );
    this.name = "UnsupportedCropException";
  }
}
