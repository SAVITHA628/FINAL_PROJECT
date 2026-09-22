# FoundIt — Campus Lost & Found Platform

> A centralized platform for reporting, searching, matching, and recovering lost and found items in college/community environments.

---

## 📌 Project Overview

**FoundIt** provides a complete end-to-end solution for managing campus lost and found items. It consists of:
1. **Flutter Mobile Application** (`foundit_app`): Mobile client for Android/iOS with real-time item reporting, search, persistent favorites, phone contact actions, and feature matching.
2. **Python AI Matching Microservice** (`foundit_ai_service`): Standalone FastAPI microservice utilizing PyTorch MobileNetV3 visual embeddings and scikit-learn TF-IDF metadata vectorization for multimodal item feature similarity scoring.
3. **React.js Admin Dashboard** (`foundit_admin`): Web interface for campus administrators to review claims, verify item reports, monitor analytics, and manage item lifecycles.
4. **Firebase Cloud Services**: Cloud Firestore NoSQL database, Firebase Authentication, Firebase Storage, and Firebase Cloud Messaging (FCM).

---

## 🛠️ Technology Stack

| Layer | Technology |
| :--- | :--- |
| **Mobile App** | Flutter 3.3.0+ / Dart |
| **State Management & Navigation** | Riverpod 2.5+, GoRouter 14.3+ |
| **Backend & Database** | Cloud Firestore NoSQL, Firebase Authentication, Firebase Storage, FCM |
| **AI Matching Microservice** | Python 3.10+, FastAPI, Uvicorn, PyTorch, Scikit-learn, NumPy |
| **Admin Dashboard** | React.js, Vite, Recharts |
| **Build & Toolchain** | Gradle, VS Code, Android Studio, Git |

---

## ⚡ Features Overview

- **User Registration & Login**: Validated email syntax, password hashing (XOR-base64), role checking (`admin` / `user`).
- **In-App Password Reset**: Instant account verification and password updates directly in Cloud Firestore.
- **Lost & Found Reporting**: Create lost/found posts with compressed image uploads, category selection, and location tagging.
- **Phone Number Privacy Separation**: Keeps account registration phone (`registrationPhone`) on Profile screen strictly separate from item contact numbers (`contactPhone` & `contactWhatsApp`).
- **Feature Matching**: Computes pairwise item similarity based on categories, titles, descriptions, and visual embeddings.
- **Persistent Favorites**: User favorites are stored directly in Cloud Firestore `users/{userId}` and persist across app reinstalls and sessions.
- **Notifications Pipeline**: Live real-time Firestore stream for user notifications.
- **Ownership Verification**: Human-in-the-loop admin verification for ownership claims before handover.
- **Admin Dashboard**: Real-time stats, TAT reports, user management, and item verification controls.

---

## 📐 Matching Architecture

FoundIt implements a dual-layer matching architecture:

1. **Standalone PyTorch AI Microservice (`foundit_ai_service`)**:
   - **Image Embedding**: Uses pre-trained `MobileNetV3-Small` (PyTorch) to generate 576-dimensional L2-normalized image embeddings.
   - **Text Similarity**: Uses `TfidfVectorizer` (scikit-learn) with Cosine Similarity across Title, Description, and Location.
   - **Multimodal Score Formula**:
     $$S_{\text{multimodal}} = 0.50 \cdot S_{\text{image}} + 0.50 \cdot S_{\text{text}}$$
     $$S_{\text{text}} = 0.35 \cdot S_{\text{category}} + 0.35 \cdot S_{\text{title}} + 0.20 \cdot S_{\text{desc}} + 0.10 \cdot S_{\text{loc}}$$
   - **Threshold**: $S_{\text{multimodal}} \ge 0.55 \implies \text{POSSIBLE\_MATCH}$.

2. **Mobile Client Similarity Fallback (`foundit_app`)**:
   - Computes weighted token similarity ($0.40 \cdot S_{\text{category}} + 0.60 \cdot S_{\text{tokens}}$) locally on device, ensuring the Android release APK runs independently without local network freezes.

---

## 📂 Project Structure

```
FOUNDIT/
├── foundit_app/          ← Flutter mobile app (Android / iOS)
├── foundit_ai_service/   ← Python FastAPI PyTorch matching microservice
├── foundit_admin/        ← React.js admin web dashboard
├── firestore.rules       ← Firestore Security Rules
├── storage.rules         ← Firebase Storage Security Rules
├── MATCHING_AUDIT.md     ← Matching algorithms documentation
├── PROJECT_TECHNICAL_AUDIT.md ← Full system architecture audit
└── .env.example          ← Environment configuration template
```

---

## 🚀 Setup & Installation Instructions

### 1. Flutter Mobile App Setup (`foundit_app`)

```bash
cd foundit_app

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit tests
flutter test

# Run app on emulator or connected phone
flutter run
```

#### Building Release APK:
```bash
flutter build apk --release
```
The output APK is generated at:
`foundit_app/build/app/outputs/flutter-apk/app-release.apk`

---

### 2. Python AI Matching Service (`foundit_ai_service`)

```bash
cd foundit_ai_service

# Create virtual environment
python -m venv venv

# Activate environment (Windows)
.\venv\Scripts\activate

# Install requirements
pip install -r requirements.txt

# Start FastAPI microservice
python main.py
# Running on http://localhost:8000
```

---

### 3. React Admin Dashboard Setup (`foundit_admin`)

```bash
cd foundit_admin

# Install dependencies
npm install

# Start development server
npm run dev
# Running on http://localhost:5173
```

---

## 🔐 Environment Variables Configuration

Copy `.env.example` to `.env` in the root folder:

```ini
PORT=8000
HOST=0.0.0.0
MATCH_THRESHOLD=0.55
IMAGE_WEIGHT=0.50
TEXT_WEIGHT=0.50
FIREBASE_PROJECT_ID=foundit-6bc8a
```
