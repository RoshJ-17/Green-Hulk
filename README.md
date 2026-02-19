# Green-Hulk 🌱

Plant Disease Detection Application with AI-powered diagnosis using TensorFlow Lite.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the Application](#running-the-application)
- [Project Structure](#project-structure)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)

---

## 🌟 Overview

Green-Hulk is a full-stack plant disease detection system consisting of:
- **Flutter Frontend** - Mobile/Desktop app for image capture and diagnosis
- **Node.js Backend (NestJS)** - REST API for image processing and orchestration
- **Python TFLite Service** - Microservice for TensorFlow Lite model inference

The system uses a pre-trained TFLite model to identify 38 different plant disease classes from leaf images.

---

## 🏗️ Architecture

```
┌─────────────────┐
│ Flutter Frontend│ (Port: Dynamic)
└────────┬────────┘
         │ HTTP POST /api/diagnose
         ▼
┌─────────────────┐
│ NestJS Backend  │ (Port: 3000)
│ - Image Upload  │
│ - Preprocessing │
└────────┬────────┘
         │ HTTP POST /predict
         ▼
┌─────────────────┐
│ Python TFLite   │ (Port: 5000)
│ - Model.tflite  │
│ - Inference     │
└─────────────────┘
```

---

## ✅ Prerequisites

### System Requirements
- **Node.js**: v22.16.0 or higher
- **Python**: 3.11.9 or higher
- **Flutter**: 3.x or higher
- **Git**: For cloning the repository

### Verify Installations
```bash
node --version    # Should show v22+
python --version  # Should show 3.11+
flutter --version # Should show 3.x+
```

---

## 📦 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/RoshJ-17/Green-Hulk.git
cd Green-Hulk
```

### 2. Backend Setup (Node.js + NestJS)

#### Install Node.js Dependencies
```bash
cd backend
npm install
```

**Required Packages:**
- `@nestjs/common`, `@nestjs/core`, `@nestjs/platform-express`
- `@tensorflow/tfjs` (for type definitions)
- `sharp` (image processing)
- `multer` (file uploads)
- `typeorm`, `sqlite3` (database)

#### Install Python Dependencies
```bash
# Still in backend directory
pip install tensorflow flask flask-cors
```

**Required Python Packages:**
- `tensorflow` (for TFLite interpreter)
- `flask` (microservice framework)
- `flask-cors` (CORS support)
- `numpy` (array operations)

### 3. Frontend Setup (Flutter)

```bash
cd ../frontend
flutter pub get
```

**Required Flutter Packages:**
- `http` (API calls)
- `camera` (image capture)
- `image_picker` (gallery selection)
- `provider` (state management)

---

## 🚀 Running the Application

You need to run **THREE** services in **separate terminals**:

### Terminal 1: Python TFLite Service

```bash
cd backend
python tflite_service.py
```

**Expected Output:**
```
============================================================
TFLite Inference Service Started
============================================================
Model: ./models/model.tflite
Input shape: [  1 224 224   3]
Output shape: [ 1 38]
Listening on port: 5000
============================================================
```

✅ **Service Ready When:** You see "Running on http://0.0.0.0:5000"

---

### Terminal 2: Node.js Backend

```bash
cd backend
npm run start:dev
```

**Expected Output:**
```
[Nest] LOG [ModelLoaderService] ✅ TFLite service is healthy - model: loaded
[Nest] LOG [NestApplication] Nest application successfully started
[Nest] LOG [Bootstrap] Application is running on: http://localhost:3000
[Nest] LOG [Bootstrap] Swagger documentation: http://localhost:3000/api/docs
```

✅ **Service Ready When:** You see "✅ TFLite service is healthy"

---

### Terminal 3: Flutter Frontend

```bash
cd frontend
flutter run
```

**For Web:**
```bash
flutter run -d chrome
```

**For Mobile (with device connected):**
```bash
flutter run
```

✅ **App Ready When:** Flutter console shows "Application started"

---

## 📁 Project Structure

```
Green-Hulk/
├── backend/
│   ├── src/
│   │   ├── api/              # Controllers (REST endpoints)
│   │   ├── ml/               # ML services
│   │   │   └── model-loader.service.ts  # Calls Python service
│   │   ├── image/            # Image processing
│   │   └── main.ts           # Entry point
│   ├── models/
│   │   ├── model.tflite      # TFLite model file
│   │   └── plant-disease-model/
│   │       └── class_indices.json  # Disease class mappings
│   ├── tflite_service.py     # Python microservice
│   ├── tflite_service_config.json
│   └── package.json
│
├── frontend/
│   ├── lib/
│   │   ├── services/
│   │   │   └── ai_model_service.dart  # Calls backend API
│   │   ├── screens/          # UI screens
│   │   └── main.dart         # Entry point
│   ├── assets/
│   │   └── model/
│   │       ├── model.tflite  # (Reference copy)
│   │       └── class_indices.json
│   └── pubspec.yaml
│
└── README.md
```

---

## 🔌 API Documentation

### Backend Endpoints

#### Health Check
```http
GET http://localhost:3000/api/health
```

#### Diagnose Plant Disease
```http
POST http://localhost:3000/api/diagnose
Content-Type: multipart/form-data

{
  "image": <file>,
  "selectedCrop": "Tomato"
}
```

**Response:**
```json
{
  "type": "success",
  "disease": "Tomato___Late_blight",
  "confidence": 0.92,
  "severity": "high",
  "cropType": "Tomato"
}
```

### Python TFLite Service Endpoints

#### Health Check
```http
GET http://localhost:5000/health
```

#### Predict
```http
POST http://localhost:5000/predict
Content-Type: application/json

{
  "input": [<150528 float32 values>]
}
```

### Swagger Documentation
Access interactive API docs at: **http://localhost:3000/api/docs**

---

## 🔧 Configuration

### Backend Configuration

**Environment Variables** (optional, in `backend/.env`):
```env
PORT=3000
MODEL_PATH=./models/model.tflite
TFLITE_SERVICE_URL=http://localhost:5000
```

### Python Service Configuration

Edit `backend/tflite_service_config.json`:
```json
{
  "modelPath": "./models/model.tflite",
  "classIndicesPath": "../frontend/assets/model/class_indices.json",
  "inputShape": [1, 224, 224, 3],
  "outputShape": [1, 38],
  "port": 5000
}
```

### Frontend Configuration

Update backend URL in `frontend/lib/services/ai_model_service.dart`:
```dart
static const String _baseUrl = 'http://192.168.1.100:3000/api';
// For Android Emulator: use 10.0.2.2
// For Physical Device: use your machine's LAN IP
```

---

## 🐛 Troubleshooting

### Issue: "TFLite service not available"

**Solution:**
1. Ensure Python service is running first (Terminal 1)
2. Check port 5000 is not in use:
   ```bash
   # Windows
   netstat -ano | findstr :5000
   
   # Linux/Mac
   lsof -i :5000
   ```

### Issue: "Port 3000 already in use"

**Solution:**
```bash
# Windows
Get-Process -Name node | Stop-Process -Force

# Linux/Mac
killall node
```

### Issue: "Module not found" errors in Python

**Solution:**
```bash
pip install tensorflow flask flask-cors numpy
```

### Issue: Backend can't find model file

**Solution:**
Verify model file exists:
```bash
ls backend/models/model.tflite
ls backend/models/plant-disease-model/class_indices.json
```

If missing, copy from frontend:
```bash
cp frontend/assets/model/model.tflite backend/models/
cp frontend/assets/model/class_indices.json backend/models/plant-disease-model/
```

### Issue: Flutter "http package not found"

**Solution:**
```bash
cd frontend
flutter pub get
flutter clean
flutter pub get
```

---

## 🧪 Testing

### Test Python Service
```bash
curl http://localhost:5000/health
# Expected: {"status": "healthy", "model": "loaded"}
```

### Test Node.js Backend
```bash
curl http://localhost:3000/api/health
# Expected: Service status JSON
```

### Test Full Pipeline
Use the Flutter app to:
1. Select a crop (e.g., "Tomato")
2. Capture/upload a leaf image
3. View diagnosis results

---

## 📝 Development Commands

### Backend

```bash
# Development mode (watch for changes)
npm run start:dev

# Production build
npm run build
npm run start:prod

# Run tests
npm test
```

### Frontend

```bash
# Run on specific device
flutter run -d <device-id>

# Build for production
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web

# Analyze code
flutter analyze
```

---

## 🔍 Implementation Details

### Why Microservice Architecture?

The `.tflite` model format is designed for mobile/edge devices and **cannot run directly in Node.js** due to browser-specific dependencies. We tried several approaches:

**❌ Failed Approaches:**
1. **Browser Global Polyfills** - TFLite requires `self`, `window`, `document`, `navigator` globals
2. **@tensorflow/tfjs-tflite** - Browser-only package, not compatible with Node.js
3. **Direct TFLite→TFJS Conversion** - `tensorflowjs_converter` had dependency resolution issues

**✅ Solution: Python Microservice**

We created a lightweight Flask service that:
- Runs the `.tflite` model using Python's native TensorFlow Lite interpreter
- Exposes simple HTTP endpoints (`/health`, `/predict`)
- Integrates seamlessly with the Node.js backend

### Benefits of This Approach

1. **Zero Conversion Overhead** - Use `.tflite` file directly, no format conversion needed
2. **Native TFLite Support** - Python has first-class TensorFlow Lite support
3. **Separation of Concerns** - ML inference isolated in dedicated service
4. **Scalability** - Python service can be scaled independently
5. **Flexibility** - Easy to add GPU acceleration or swap models
6. **No Polyfills** - Avoids complex browser dependency workarounds

### TypeScript Errors Fixed

During implementation, we resolved two critical TypeScript errors:

**Error 1:** `Cannot find module '@tensorflow/tfjs-node'`
- **Fix:** Removed the import, switched to HTTP-based microservice architecture

**Error 2:** `Object is possibly 'null'`
- **Fix:** Added null safety check: `if (this.model) { this.model.predict(...) }`

### Files Created

**Backend:**
- `tflite_service.py` - Flask microservice for TFLite inference
- `tflite_service_config.json` - Configuration (model path, port, shapes)
- `inspect_model.py` - Utility to inspect model metadata
- `convert_model.py` - Model conversion utilities (reference)

**Frontend:**
- Updated `ai_model_service.dart` to call backend API instead of local TFLite
- Added HTTP dependencies to `pubspec.yaml`

---

## 📊 Model Conversion Notes

### Current Setup (No Conversion Needed)

The `.tflite` model runs directly in the Python microservice - **no conversion required**.

### If You Need to Convert Models

If you want to use a different model format or convert TFLite to TensorFlow.js:

**Inspect Your Model:**
```bash
cd backend
python inspect_model.py
```

This generates `models/model_info.json` with input/output shapes.

**Convert TFLite to TFJS (Optional):**
```bash
# Install converter
pip install tensorflowjs

# Convert
tensorflowjs_converter \
  --input_format=tf_lite \
  --output_format=tfjs_graph_model \
  ./models/model.tflite \
  ./models/tfjs_model
```

**Note:** Conversion is **not required** for the current architecture. The Python service handles `.tflite` natively.

---

## 🎯 Model Information

- **Format:** TensorFlow Lite (`.tflite`)
- **Input Shape:** `[1, 224, 224, 3]` (RGB image, normalized 0-1)
- **Output Shape:** `[1, 38]` (probability distribution over 38 disease classes)
- **Classes:** See `backend/models/plant-disease-model/class_indices.json`

---

## 📄 License

MIT License

---

## 🚀 Quick Start (TL;DR)

```bash
# 1. Clone & setup
git clone https://github.com/RoshJ-17/Green-Hulk.git
cd Green-Hulk

# 2. Install dependencies
cd backend && npm install && pip install tensorflow flask flask-cors && cd ..
cd frontend && flutter pub get && cd ..

# 3. Run services (3 separate terminals)
# Terminal 1:
cd backend && python tflite_service.py

# Terminal 2:
cd backend && npm run start:dev

# Terminal 3:
cd frontend && flutter run
```
