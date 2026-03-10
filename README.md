# Green-Hulk 🌱

AI-powered plant disease detection app — scan a leaf, get instant diagnosis, treatment plans, weather spray advisories, and more.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
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
- **Flutter Frontend** — Mobile app for image capture, video scan, diagnosis results, treatments, and more
- **Node.js Backend (NestJS)** — REST API for image processing, auth, scan history, and orchestration
- **Python TFLite Service** — Lightweight Flask microservice that runs TensorFlow Lite model inference

The system uses a pre-trained TFLite model trained on the PlantVillage dataset to identify **38 plant disease classes** across 14 crop types.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📸 **Single-shot scan** | Capture a leaf photo and get instant AI diagnosis |
| 🎥 **Video multi-frame scan** | 3-frame rapid capture with majority-vote consensus for higher accuracy |
| 🌦️ **Weather spray advisory** | Real-time wind, rain & humidity check — tells you the best time to spray chemicals |
| 💊 **Medicine dosage calculator** | Calculate exact chemical/water quantities for your field size (acre / hectare / bigha) |
| ⚠️ **Chemical safety checklist** | PPE requirements, toxicity badge, bee pollinator warning, after-spray instructions |
| 🌿 **Enhanced prevention** | Disease-specific prevention + crop rotation, soil health, and resistant variety tips |
| 🗣️ **Voice crop search** | Speak the crop name instead of typing |
| 📜 **Scan history** | Local + server-synced history of all previous diagnoses |
| 🌐 **Multi-language UI** | English, Hindi, Tamil, Telugu, Kannada, Bengali, Punjabi |
| 📴 **Offline queue** | Scans queued while offline, auto-synced when connectivity returns |
| 🔔 **OTA update check** | Notifies users when a new app version is available |

---

## 🏗️ Architecture

```
┌───────────────────────────────────┐
│         Flutter App               │
│  - Onboarding / Auth              │
│  - Camera (single + video scan)   │
│  - Treatment + Weather advisory   │
│  - Medicine & Safety widgets      │
│  - History / Settings             │
└────────────────┬──────────────────┘
                 │ POST /api/diagnose  (multipart: image + selectedCrop)
                 ▼
┌───────────────────────────────────┐
│       NestJS Backend :3000        │
│  - Auth (OTP / JWT)               │
│  - Image quality & crop checks    │
│  - Treatments / Localization      │
│  - Scan history (SQLite)          │
└────────────────┬──────────────────┘
                 │ POST /predict  (flat Float32 [1,224,224,3])
                 ▼
┌───────────────────────────────────┐
│   Python Flask TFLite :5000       │
│  - model.tflite inference         │
│  - Returns 38 probabilities       │
└───────────────────────────────────┘
```

---

## ✅ Prerequisites

### System Requirements
- **Node.js**: v22+ 
- **Python**: 3.11+
- **Flutter**: 3.x (Dart SDK ^3.9.0)
- **Git**

### Verify Installations
```bash
node --version    # v22+
python --version  # 3.11+
flutter --version # 3.x
```

---

## 📦 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/RoshJ-17/Green-Hulk.git
cd Green-Hulk
```

### 2. Backend Setup

```bash
cd backend
npm install
pip install tensorflow flask flask-cors numpy
```

### 3. Frontend Setup

```bash
cd ../frontend
flutter pub get
```

---

## 🚀 Running the Application

Run **three services** in separate terminals:

### Terminal 1 — Python TFLite Service

```bash
cd backend
python tflite_service.py
```

**Expected:**
```
TFLite Inference Service Started
Model: ./models/model.tflite  |  Input: [1,224,224,3]  |  Output: [1,38]
Running on http://0.0.0.0:5000
```

---

### Terminal 2 — NestJS Backend

```bash
cd backend
npm run start:dev
```

**Expected:**
```
[ModelLoaderService] ✅ TFLite service is healthy - model: loaded
[Bootstrap] Application is running on: http://localhost:3000
[Bootstrap] Swagger docs: http://localhost:3000/api/docs
```

---

### Terminal 3 — Flutter App

```bash
cd frontend
flutter run                    # connected device / emulator
flutter run -d chrome          # web
```

---

## 📁 Project Structure

```
Green-Hulk/
├── backend/
│   ├── src/
│   │   ├── api/                     # REST controllers
│   │   │   ├── diagnosis.controller.ts
│   │   │   ├── scans.controller.ts
│   │   │   ├── treatments.controller.ts
│   │   │   ├── localization.controller.ts
│   │   │   ├── preferences.controller.ts
│   │   │   └── version.controller.ts
│   │   ├── auth/                    # OTP + JWT auth
│   │   ├── diagnosis/               # 8-step diagnosis pipeline
│   │   │   ├── diagnosis.service.ts
│   │   │   └── helpers/             # confidence + severity helpers
│   │   ├── image/                   # sharp-based preprocessing
│   │   ├── ml/
│   │   │   ├── model-loader.service.ts   # calls Python /predict
│   │   │   └── label-loader.service.ts   # loads class_indices.json
│   │   ├── database/                # TypeORM + SQLite scan records
│   │   ├── common/                  # OOD detector, crop validator, quality checker
│   │   ├── treatments/              # treatment data service
│   │   ├── localization/            # i18n service
│   │   └── validators/
│   ├── models/
│   │   ├── model.tflite             # TFLite model (38 classes, PlantVillage)
│   │   ├── class_indices.json       # label → index mapping
│   │   └── model_info.json          # input/output shape metadata
│   ├── tflite_service.py            # Flask inference microservice
│   ├── tflite_service_config.json
│   ├── inspect_model.py             # utility: print model metadata
│   └── package.json
│
└── frontend/
    ├── lib/
    │   ├── main.dart
    │   ├── config/
    │   │   └── api_config.dart      # base URL resolution per platform
    │   ├── models/
    │   │   └── scan_result.dart
    │   ├── services/
    │   │   ├── ai_model_service.dart       # POST /api/diagnose, image optimisation
    │   │   ├── video_scan_service.dart     # 3-frame rapid capture + majority vote
    │   │   ├── weather_service.dart        # WeatherAPI spray advisory
    │   │   ├── auth_service.dart           # OTP / JWT login
    │   │   ├── history_service.dart        # local + server scan history
    │   │   ├── treatment_api_service.dart  # GET /api/treatments/*
    │   │   ├── connectivity_service.dart   # online/offline detection
    │   │   ├── pending_upload_service.dart # offline scan queue
    │   │   ├── voice_search_service.dart   # speech-to-text crop search
    │   │   ├── audio_service.dart          # button / shutter / result sounds
    │   │   ├── camera_service.dart         # camera initialisation
    │   │   ├── farmer_crop_service.dart    # crop selection state
    │   │   ├── localization_service.dart   # 7-language translations
    │   │   ├── app_state.dart              # global ChangeNotifier
    │   │   └── update_service.dart         # OTA version check
    │   ├── screens/
    │   │   ├── onboarding_screen.dart      # redesigned Get Started screen
    │   │   ├── splash_screen.dart
    │   │   ├── language_selection_screen.dart
    │   │   ├── login_screen.dart
    │   │   ├── signup_screen.dart
    │   │   ├── navigation_wrapper.dart
    │   │   ├── dashboard_screen.dart
    │   │   ├── scan_camera_screen.dart     # single + video scan
    │   │   ├── treatment_screen.dart       # treatment + weather + calculator
    │   │   ├── history_screen.dart
    │   │   ├── crop_selection_screen.dart
    │   │   ├── map_screen.dart
    │   │   └── settings_screen.dart
    │   └── widgets/
    │       ├── weather_advisory_card.dart    # spray advisory card
    │       ├── medicine_calculator_widget.dart  # dosage calculator
    │       ├── chemical_safety_widget.dart   # PPE checklist + toxicity
    │       ├── prevention_section_widget.dart # crop rotation, soil, seeds
    │       └── shared_widgets.dart
    ├── assets/
    │   ├── images/
    │   │   ├── onboarding_background.png
    │   │   ├── onboarding_scan_leaf.png
    │   │   ├── onboarding_ai_analysis.png
    │   │   └── onboarding_solutions.png
    │   ├── model/
    │   │   ├── model.tflite          # (reference copy for future on-device use)
    │   │   └── class_indices.json
    │   ├── icons/
    │   └── app_icon.png
    └── pubspec.yaml
```

---

## 🔌 API Documentation

### Diagnosis

```http
POST http://localhost:3000/api/diagnose
Content-Type: multipart/form-data

image        = <leaf image file>
selectedCrop = "Tomato"   # or "any"
```

**Success response:**
```json
{
  "type": "success",
  "disease": "Late Blight",
  "fullLabel": "Tomato___Late_blight",
  "confidence": 0.92,
  "severity": "Severe",
  "cropType": "Tomato"
}
```

**Error response types:** `wrongCrop` · `lowConfidence` · `outOfDistribution` · `poorQuality`

---

### Other Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/api/crops` | List of supported crop names |
| GET | `/api/diseases/:crop` | Diseases for a specific crop |
| GET | `/api/treatments/:key` | Full treatment plan |
| GET | `/api/scans/history` | Paginated scan history |
| GET | `/api/scans/stats` | Scan statistics |
| POST | `/api/scans/sync` | Sync offline scans |
| POST | `/auth/send-otp` | Send OTP to phone |
| POST | `/auth/verify-otp` | Verify OTP |
| POST | `/auth/login` | Login (returns JWT) |
| GET | `/api/version` | Current app version info |

**Swagger UI:** `http://localhost:3000/api/docs`

---

## 🎯 Model Information

| Property | Value |
|---|---|
| Format | TensorFlow Lite (`.tflite`) |
| Input shape | `[1, 224, 224, 3]` — RGB, normalised 0–1 |
| Output shape | `[1, 38]` — probability over 38 classes |
| Dataset | PlantVillage |
| Crops covered | Apple, Blueberry, Cherry, Corn, Grape, Orange, Peach, Pepper bell, Potato, Raspberry, Soybean, Squash, Strawberry, Tomato |

---

## ⚙️ Configuration

### Backend — `.env` (optional)

```env
PORT=3000
TFLITE_SERVICE_URL=http://localhost:5000
LABELS_PATH=./models/class_indices.json
```

### Frontend — URL resolution ([frontend/lib/config/api_config.dart](frontend/lib/config/api_config.dart))

| Target | URL |
|---|---|
| Android Emulator | `http://10.0.2.2:3000/api` |
| iOS Simulator / Desktop | `http://127.0.0.1:3000/api` |
| Web | same-origin |
| Override | `--dart-define=BACKEND_URL=http://192.168.x.x:3000/api` |

---

## 🐛 Troubleshooting

### "TFLite service not available"
Start the Python service first (`python tflite_service.py`), then the NestJS backend.

### Port conflicts
```powershell
# Kill Node on port 3000
Get-Process -Name node | Stop-Process -Force

# Check what's on port 5000
netstat -ano | findstr :5000
```

### Flutter build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Missing model file
```bash
# Copy from frontend assets to backend models
cp frontend/assets/model/model.tflite backend/models/model.tflite
```

---

## 📝 Development Commands

### Backend
```bash
npm run start:dev    # watch mode
npm run build        # production build
npm test             # unit tests
```

### Frontend
```bash
flutter run                  # run on connected device
flutter run -d chrome        # web
flutter analyze              # lint
flutter build apk            # Android release
flutter build ios            # iOS release
flutter build web            # Web release
```

---

## 🚀 Quick Start (TL;DR)

```bash
# Clone
git clone https://github.com/RoshJ-17/Green-Hulk.git
cd Green-Hulk

# Dependencies
cd backend && npm install && pip install tensorflow flask flask-cors numpy
cd ../frontend && flutter pub get && cd ..

# Run (3 terminals)
# T1:  cd backend && python tflite_service.py
# T2:  cd backend && npm run start:dev
# T3:  cd frontend && flutter run
```

---

## 📄 License

MIT License

