import { Injectable } from "@nestjs/common";

@Injectable()
export class SupportedClassesService {
  // Exact 38 classes from class_indices.json
  private readonly MODEL_CLASSES = new Set([
    "Apple___Apple_scab",
    "Apple___Black_rot",
    "Apple___Cedar_apple_rust",
    "Apple___healthy",
    "Blueberry___healthy",
    "Cherry_(including_sour)___Powdery_mildew",
    "Cherry_(including_sour)___healthy",
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot",
    "Corn_(maize)___Common_rust_",
    "Corn_(maize)___Northern_Leaf_Blight",
    "Corn_(maize)___healthy",
    "Grape___Black_rot",
    "Grape___Esca_(Black_Measles)",
    "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)",
    "Grape___healthy",
    "Orange___Haunglongbing_(Citrus_greening)",
    "Peach___Bacterial_spot",
    "Peach___healthy",
    "Pepper,_bell___Bacterial_spot",
    "Pepper,_bell___healthy",
    "Potato___Early_blight",
    "Potato___Late_blight",
    "Potato___healthy",
    "Raspberry___healthy",
    "Soybean___healthy",
    "Squash___Powdery_mildew",
    "Strawberry___Leaf_scorch",
    "Strawberry___healthy",
    "Tomato___Bacterial_spot",
    "Tomato___Early_blight",
    "Tomato___Late_blight",
    "Tomato___Leaf_Mold",
    "Tomato___Septoria_leaf_spot",
    "Tomato___Spider_mites Two-spotted_spider_mite",
    "Tomato___Target_Spot",
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus",
    "Tomato___Tomato_mosaic_virus",
    "Tomato___healthy",
  ]);

  private readonly SUPPORTED_CROPS = new Set([
    "Apple",
    "Blueberry",
    "Cherry",
    "Corn",
    "Grape",
    "Orange",
    "Peach",
    "Pepper",
    "Potato",
    "Raspberry",
    "Soybean",
    "Squash",
    "Strawberry",
    "Tomato",
  ]);

  private readonly CROP_STATISTICS = {
    Tomato: 10,
    Apple: 4,
    Corn: 4,
    Grape: 4,
    Potato: 3,
    Cherry: 2,
    Peach: 2,
    Pepper: 2,
    Strawberry: 2,
    Blueberry: 1,
    Orange: 1,
    Raspberry: 1,
    Soybean: 1,
    Squash: 1,
  };

  getSupportedCrops(): string[] {
    return Array.from(this.SUPPORTED_CROPS);
  }

  isCropSupported(cropName: string): boolean {
    const normalized = this.normalizeCropName(cropName);
    return this.SUPPORTED_CROPS.has(normalized);
  }

  normalizeCropName(crop: string): string {
    // Handle variations: "Pepper,_bell" -> "Pepper", "Corn_(maize)" -> "Corn"
    return crop.split(/[,_(]/)[0].trim();
  }

  getDiseasesForCrop(cropName: string, allLabels: string[]): string[] {
    const normalized = this.normalizeCropName(cropName);
    return allLabels
      .filter((label) => {
        const labelCrop = this.normalizeCropName(label.split("___")[0]);
        return labelCrop === normalized;
      })
      .map((label) => label.split("___")[1]);
  }

  getCropStatistics(): Record<string, number> {
    return { ...this.CROP_STATISTICS };
  }

  isClassSupported(className: string): boolean {
    return this.MODEL_CLASSES.has(className);
  }
}
