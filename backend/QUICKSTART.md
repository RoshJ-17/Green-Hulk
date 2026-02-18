# Quick Start Guide

## Setup Steps

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Convert Model (See MODEL_CONVERSION.md)

```bash
# Install Python dependencies
pip install tensorflowjs tensorflow

# Convert TFLite to TensorFlow.js
# (Follow detailed instructions in MODEL_CONVERSION.md)
```

### 3. Setup Assets

```bash
# Create directories
mkdir -p assets/model
mkdir -p data

# Copy class indices
cp ../class_indices.json assets/

# Ensure model files are in assets/model/
# - model.json
# - *.bin files
```

### 4. Configure Environment

```bash
# .env is already created with defaults
# Verify paths are correct:
cat .env
```

### 5. Run the Application

```bash
# Development mode (with hot reload)
npm run start:dev

# Production mode
npm run build
npm run start:prod
```

### 6. Verify Installation

Open browser: `http://localhost:3000/api/docs`

You should see the Swagger API documentation.

### 7. Test with Sample Image

```bash
# Get a sample image from the dataset
cd ../Plant_leave_diseases_dataset_without_augmentation/Tomato___Early_blight

# Test diagnosis
curl -X POST http://localhost:3000/api/diagnose \
  -F "image=@image_001.JPG" \
  -F "selectedCrop=Tomato"
```

Expected response:
```json
{
  "type": "success",
  "disease": "Early_blight",
  "confidence": 0.85,
  "severity": "Medium",
  "cropType": "Tomato",
  "fullLabel": "Tomato___Early_blight"
}
```

## Troubleshooting

### Model Not Found
```
Error: Model file not found at path: ./assets/model/model.json
```
**Solution:** Ensure model conversion completed and files are in `assets/model/`

### Labels Not Found
```
Error: Labels file not found
```
**Solution:** Copy `class_indices.json` to `assets/` directory

### Port Already in Use
```
Error: Port 3000 is already in use
```
**Solution:** Change PORT in `.env` file or kill process using port 3000

### TensorFlow.js Errors
```
Error: Failed to load model
```
**Solution:** Verify model.json format is correct and .bin files are present

## API Endpoints

- **POST /api/diagnose** - Diagnose disease from image
- **GET /api/crops** - List supported crops
- **GET /api/diseases/:crop** - Get diseases for crop
- **GET /api/scans** - Scan history
- **DELETE /api/scans/:id** - Delete scan
- **GET /api/docs** - Swagger documentation

## Development

```bash
# Run tests
npm run test

# Run linter
npm run lint

# Format code
npm run format

# Build for production
npm run build
```

## Next Steps

1. ✅ Convert TFLite model to TensorFlow.js
2. ✅ Test with sample images from dataset
3. ⏭️ Integrate with Flutter frontend
4. ⏭️ Deploy to production server
5. ⏭️ Add treatment recommendations
6. ⏭️ Implement sync functionality
