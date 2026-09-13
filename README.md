# MediMind Pro — Clinical Edition 🩺💊

> **The Intelligent, Offline-First Medication & Ophthalmic Clinical Health Platform**  
> Built with Flutter • Android 37 Ready • 100% On-Device Privacy • Samsung One UI 7 & Apple iOS 18 Dynamic Island Design.

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android%20API-37%20(Compile)-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20On--Device-10B981?style=for-the-badge&logo=shield&logoColor=white)](#privacy--data-security)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

---

## 🌟 Overview

**MediMind Pro** is a commercial-grade personal healthcare platform engineered for patients managing complex medication regimens, post-operative recovery, chronic conditions, and delicate ophthalmic therapies. Unlike generic reminder apps that fail when OEM battery savers sleep background processes or compromise patient privacy by uploading health records to remote clouds, MediMind Pro runs **100% on-device** with high-precision alarm engines, clinical cross-interaction safeguards, and emergency first-responder integration.

---

## 🚀 Key Clinical & Architectural Features

### 👁️ 1. Ophthalmic Eye Drop & Spacing Protocol
* **Washout Prevention Timer**: Enforces critical 5–10 minute spacing between successive eye drops to avoid drug dilution and therapeutic washout.
* **28-Day Opened Bottle Shelf-Life Guard**: Automatically tracks opening dates for eye drop solutions and issues clinical alerts when bottles reach their sterility threshold.
* **Eye Selection & Technique Guidance**: Left Eye (OS), Right Eye (OD), or Both Eyes (OU) with animated technique walkthroughs.

### 📦 2. Smart Refill & Inventory Predictor
* **Mathematical Depletion Forecasting**: Computes daily dosage burn rates across complex frequencies and projects exact calendar depletion dates.
* **Visual Stock Gauges**: Real-time battery status gauges with color-coded safety thresholds.
* **1-Tap Pharmacy Order Dispatch**: Formats and dispatches official prescription re-order messages directly to pharmacies via WhatsApp, SMS, or system Share Sheet.

### 🛡️ 3. Clinical Cross-Interaction Matrix
* **Drug-Drug Cross Interactions**: Real-time multi-drug cross-referencing for dangerous conflicts (e.g., Warfarin + NSAIDs bleeding risks, ACEI + Potassium-sparing diuretics hyperkalemia).
* **Food & Beverage Conflict Warnings**: Clinical dietary alerts for Grapefruit (CYP3A4 inhibition), Dairy & Calcium (chelation with antibiotics), Alcohol, and High-Potassium diets.
* **Disease-Drug Contraindication Guards**: Cross-references patient profile conditions (Asthma vs. Beta-blockers, Peptic Ulcer vs. NSAIDs, Glaucoma vs. Anticholinergics).

### 🚨 4. Emergency Medical ID & First-Responder Fast-Pass
* **Offline Scannable QR Code**: Embeds blood type, allergies, conditions, and active prescriptions into a high-contrast QR code scannable by paramedics without internet connectivity.
* **ICE Contacts Speed Dial**: 1-tap emergency dialer for primary care physicians and next-of-kin contacts.

### 📷 5. Machine Learning OCR Prescription Scanner
* **On-Device Text Recognition**: Powered by Google ML Kit to extract medication names, strengths, dosages, and frequencies from prescription labels in seconds.

### 🎙️ 6. Hands-Free Voice Assistant
* **Natural Voice Scheduling**: Offline speech-to-text parser allowing natural voice commands (*"Remind me to take eye drops at 8 AM"*).

### 🔋 7. OEM Device Reliability Engine
* **Manufacturer-Specific Whitelisting**: Automated detection and tailored step-by-step setup guides for aggressive battery savers across **Samsung (One UI)**, **Vivo (iManager)**, **Xiaomi (HyperOS/MIUI)**, **OPPO/Realme (ColorOS)**, **OnePlus (OxygenOS)**, and **Apple iOS**.
* **Reliability Health Score**: Live diagnostic rating (10%–100%) indicating background alarm safety.

### 🎨 8. Next-Gen Dual Adaptive UI
* **Apple iOS 18 Dynamic Island**: Floating, expanding top pill displaying active countdowns, eye drop spacing intervals, and upcoming doses.
* **Samsung One UI 7 Ergonomics**: Upper viewing zone with large typography and lower thumb-interaction zone for effortless one-handed use.
* **Liquid Glassmorphism**: High-performance frosted glass backdrops, squircle components, and tactile haptic feedback.

### 📊 9. Adherence Analytics & Clinical PDF Export
* Interactive adherence percentage charts, streak counters, and comprehensive PDF report generation for physician consultations.

---

## 🏗️ Project Architecture

`
medication_reminder/
├── android/                   # Native Android host (Gradle 8.11.1, AGP 8.9.1, Kotlin 2.2.20)
│   ├── app/
│   │   ├── build.gradle.kts   # Android 37 compile SDK & R8 ProGuard configuration
│   │   └── proguard-rules.pro # ML Kit & Play Core R8 keep rules
├── assets/                    # Audio chimes, Lottie animations, illustrations
├── lib/
│   ├── data/
│   │   ├── repositories/      # Single-source-of-truth MedicationRepository
│   │   └── services/          # Notification, Storage, DeviceIntegration, Interaction, AI, Tasker
│   ├── domain/
│   │   └── models/            # Medication, Log, UserProfile, SymptomLog, AppSettings
│   ├── ui/
│   │   ├── core/              # One UI widgets, Dynamic Island, Apple Glass, Theme
│   │   └── features/
│   │       ├── dashboard/     # Unified clinical dashboard & quick access hub
│   │       ├── medications/   # Medication list, Refill tracker, Interaction matrix
│   │       ├── profile/       # Patient profile & Emergency Medical ID
│   │       ├── eye_drop_assistant/ # Ophthalmic timers & protocols
│   │       ├── ocr_scanner/   # ML Kit camera text recognition
│   │       ├── voice_assistant/# Speech-driven medication scheduling
│   │       ├── symptom_diary/ # Side effect logging & urgent escalation
│   │       └── reports/       # PDF export & adherence charts
│   └── main.dart              # MultiProvider application entry point
├── pubspec.yaml               # Flutter dependencies & assets
└── MEMORY.md                  # Claudemem persistent architectural records
`

---

## 🛠️ Tech Stack & Key Libraries

| Library | Version | Purpose |
|---|---|---|
| **Flutter SDK** | ^3.47.0 | Cross-platform core framework |
| **Provider** | ^6.1.5 | Reactive state management & repository injection |
| **Flutter Local Notifications** | ^22.3.0 | Exact alarm scheduling & lock-screen wake |
| **Google ML Kit Text Recognition** | ^0.17.1 | On-device prescription OCR |
| **QR Flutter** | ^4.1.0 | Paramedic Fast-Pass offline QR rendering |
| **Share Plus** | ^13.3.0 | Pharmacy dispatch & Medical ID sharing |
| **Speech to Text / Flutter TTS** | ^7.4.0 / ^4.2.2 | Voice command scheduling & audible countdowns |
| **PDF & Printing** | ^3.13.0 / ^5.15.0 | Physician-ready clinical adherence export |
| **FL Chart** | ^1.2.0 | Interactive medication intake visualization |

---

## 🔒 Privacy & Data Security

* **Zero Cloud Dependence**: All medical profiles, medication names, dosage histories, and symptom diaries are stored locally on the device using encrypted preferences.
* **No Telemetry / No Tracking**: Zero analytics SDKs or third-party trackers are bundled.
* **Biometric / PIN App Lock**: Protects health data against unauthorized physical access.

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK 3.47.x or higher
* Android SDK 37
* Java 17 LTS (OpenJDK 17)

### Installation & Build

`ash
# 1. Clone repository
git clone https://github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>.git
cd <YOUR_REPO_NAME>

# 2. Install dependencies
flutter pub get

# 3. Verify static analysis
flutter analyze

# 4. Run in debug mode
flutter run

# 5. Build production Release APK
flutter build apk --release
`

The compiled release APK will be generated at:
`
build/app/outputs/flutter-apk/app-release.apk
`

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
