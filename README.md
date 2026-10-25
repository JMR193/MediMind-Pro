# MediMind Pro — Clinical & Research Edition 🩺💊

> **The Intelligent, Offline-First Medication & Ophthalmic Clinical Companion**  
> Built with Flutter • Android 37 Ready • 100% On-Device Privacy • Calming Clinical UX • Zero Cloud Telemetry

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android%20API-37%20(Compile)-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20On--Device-10B981?style=for-the-badge&logo=shield&logoColor=white)](#-privacy--security-first-architecture)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

---

## 🌟 Overview

**MediMind Pro** is a modern, commercial-grade personal healthcare platform engineered specifically for patients managing complex medication regimens, post-operative surgical recoveries, chronic multi-therapy protocols, and specialized ophthalmic regimens.

Unlike conventional reminder applications that sleep during aggressive OEM battery optimizations or compromise privacy by uploading sensitive health records to remote cloud servers, MediMind Pro operates **100% on-device** with high-precision background alarm scheduling, deterministic clinical interaction safeguards, automated prescription handwriting recognition, and first-responder emergency integration.

---

## 🚀 Key Clinical & Architectural Features

### 👁️ 1. Ophthalmic Specialty & Post-Op Regimen Hub
* **Clinical Formulation Ladder**: Automatically enforces proper sequencing across physical drug formulations to prevent wash-out:
  1. *Clear Solutions* (fastest corneal penetration)
  2. *Suspensions* (shaking reminder for Pred Forte, Nevanac, Besivance)
  3. *Emulsions* (milky formulations)
  4. *Gels* (viscous drops)
  5. *Ointments* (bedtime application)
* **Washout Spacing Timer**: Enforces a strict 5-minute spacing countdown between successive drops to prevent drug dilution and loss of therapeutic efficacy.
* **Guided Punctal Occlusion**: 60-second guided anatomical countdown with vibration and auditory cues to minimize systemic absorption of beta-blockers (e.g., Timolol) and prevent systemic cardiovascular side effects.
* **Subspecialty Post-Op Presets**: 1-tap import for standardized protocols across **Cataract (Phaco)**, **Glaucoma (Target-IOP)**, **Cornea & Keratoplasty**, **Refractive (LASIK/PRK)**, **Vitreoretinal (Post-Vitrectomy)**, and **Orbit / Oculoplastics** *(zero proprietary hospital names — pure clinical subspecialty protocols)*.
* **Emergency RSVP Red-Flag Triage**: Instant screening for **R**edness, **S**ensitivity to light, **V**ision loss, and severe throbbing **P**ain with speed-dial escalation to on-call clinical care.

### 🧠 2. RxNLP 2.0 Prescription Understanding Algorithm
* **Indian Matrix Notation**: Seamlessly decodes matrix dosing schedules (`1-0-1`, `1-1-1`, `1-0-0`, `0-0-1`, `1-0-1-1`) into exact morning, afternoon, evening, and bedtime schedule times.
* **Latin Medical Sigs**: Parses high-frequency and post-op sigs (`Q1H`, `Q2H`, `Q6H`, `TID`, `BID`, `QID`, `QHS`, `PRN`, `STAT`).
* **Automated 4-Week Steroid Taper**: Detects tapering schedules (`4-3-2-1`, `weekly taper`) and automatically configures a step-down regimen (Week 1: 4x/day $\rightarrow$ Week 2: 3x/day $\rightarrow$ Week 3: 2x/day $\rightarrow$ Week 4: 1x/day $\rightarrow$ Stop).
* **OCR De-mangle & Levenshtein Fuzzy Correction**: Cleans printer artifacts, stamps, hospital header noise, and autocorrects handwriting typos against a verified clinical drug dictionary.

### 🌿 3. Calming Real-Time Healthcare UI & Experience
* **Calming Green Aesthetic**: Therapeutic forest and soft mint tones (`#2D6A4F`, `#52B788`, `#D8F3DC`, `#F4FBF7`) engineered for patient tranquility and clarity.
* **Live Today's Progress Card**: Real-time counter showing `X of Y doses completed` with percentage adherence tracking.
* **1-Tap Instant Dose Logging**: Real-time `✓ Take Dose` (instant repository logging, inventory decrement, adherence calculation, and haptic feedback) and `⏰ Snooze` buttons.
* **Pip AI Companion Mascot**: Friendly vector companion (`MediBuddyCharacter`) providing empathetic encouragement, hydration tips, and drop reminders.
* **Active Eye Drop Banner**: Persistent live banner displaying active countdown timers between sequential drops.
* **Inventory Refill Alert**: Proactive banner alerting patients to near-empty medications before stock depletion occurs.

### 🛡️ 4. Clinical Cross-Interaction & Safety Radar
* **Drug-Drug Cross-Interactions**: Real-time screening for major interactions (e.g., Warfarin + Aspirin/NSAIDs bleeding risks, Potassium-sparing diuretics + ACE inhibitors).
* **Dietary & Food Conflicts**: Evidence-based alerts for Grapefruit (CYP3A4 inhibition), Dairy & Calcium (tetracycline/fluoroquinolone chelation), Alcohol, and High-Sodium diets.
* **Contraindication Guards**: Cross-references patient profile conditions against prescriptions (e.g., Asthma vs. non-selective beta-blockers, Peptic Ulcers vs. NSAIDs).
* **AGS Beers Criteria 2023**: Pharmacovigilance screening for anticholinergics and high-risk sedative medications in seniors aged 65+.

### 🚨 5. Paramedic Emergency Medical ID & Fast-Pass
* **Offline Scannable QR Code**: Encodes blood type, allergies, chronic conditions, and active prescriptions into a high-contrast QR code readable by first responders without internet connectivity.
* **ICE Contacts Speed Dial**: 1-tap emergency dialer for primary care physicians, guardians, and emergency services.

### 📦 6. Mathematical Refill & Stock Forecasting
* **Burn-Rate Analytics**: Computes daily consumption rates across complex schedules and forecasts exact calendar depletion dates.
* **Visual Battery Gauges**: Color-coded stock level indicators (Green $\rightarrow$ Amber $\rightarrow$ Red).
* **1-Tap Reorder Dispatch**: Generates pre-formatted prescription reorder messages for WhatsApp, SMS, or system share sheets.

### 🔋 7. OEM Device Reliability & Battery Whitelisting
* **Aggressive Battery Saver Whitelisting**: Automated device detection with tailored step-by-step setup guides for **Samsung (One UI)**, **Xiaomi (HyperOS/MIUI)**, **Vivo (iManager)**, **OPPO/Realme (ColorOS)**, and **OnePlus (OxygenOS)**.
* **Reliability Health Score**: Live diagnostic rating indicating background alarm safety.

---

## 🏗️ Project Architecture

```
medication_reminder/
├── android/                         # Native Android host (AGP 8.9.1, Gradle 8.11.1, Kotlin 2.2.20)
│   ├── app/
│   │   ├── build.gradle.kts         # Android SDK 37 compileSdk configuration
│   │   └── proguard-rules.pro       # R8 code shrinking & keep rules
│   └── settings.gradle.kts          # Plugin dependencies & repositories
├── assets/                          # Audio chimes, icons, clinical reference assets
├── lib/
│   ├── data/
│   │   ├── repositories/            # Central single-source MedicationRepository
│   │   └── services/                # Notification, Storage, Prescription Parser, Interaction, Tasker
│   ├── domain/
│   │   └── models/                  # Medication, Log, UserProfile, TaperPlan, ClinicalVitals
│   ├── ui/
│   │   ├── core/                    # Floating navbar, decorations, theme tokens
│   │   └── features/
│   │       ├── dashboard/           # Unified real-time clinical dashboard & progress tracking
│   │       ├── alarm/               # High-contrast heads-up MedicineAlarmDialog
│   │       ├── medications/         # Cabinet list, Refill tracker, Tapering wizard, Interactions
│   │       ├── eye_drop_assistant/  # Formulation ladder, Post-op hub, Punctal occlusion coach
│   │       ├── companion/           # Pip MediBuddy mascot & empathetic coaching
│   │       ├── ocr_scanner/         # Machine learning camera prescription scanning
│   │       ├── profile/             # Patient profiles & Paramedic Emergency Medical ID
│   │       ├── symptom_diary/       # Side-effect tracking & urgent escalation
│   │       └── reports/             # Longitudinal adherence charts & physician PDF export
│   └── main.dart                    # Application entry point & MultiProvider DI tree
├── test/                            # Comprehensive automated clinical & unit test suite
├── pubspec.yaml                     # Flutter dependencies & metadata
└── MEMORY.md                        # Architectural decisions & changelog
```

---

## 🛠️ Tech Stack & Key Libraries

| Component | Library / Version | Clinical Purpose |
|---|---|---|
| **Framework** | Flutter SDK (`^3.47.0`) | High-performance, cross-platform client architecture |
| **Language** | Dart (`^3.13.2`) | Sound null-safe AOT compiled execution |
| **State Management** | `provider: ^6.1.5` | Reactive repository injection & real-time updates |
| **Alarms & Scheduling** | `flutter_local_notifications: ^22.3.0` | Exact alarm scheduling with lock-screen wake capability |
| **Timezone & Circadian** | `timezone: ^0.11.1`, `flutter_timezone: ^5.0.3` | Shift-proof circadian timing across timezones |
| **Persistence Engine** | `shared_preferences: ^2.5.5`, `flutter_secure_storage: ^11.0.0` | Dual-storage engine with Write-Ahead Logging (`ResilientStorageEngine`) |
| **Computer Vision OCR** | `google_mlkit_text_recognition: ^0.17.1` | 100% on-device prescription label recognition |
| **Offline Medical ID** | `qr_flutter: ^4.1.0` | Paramedic Fast-Pass scannable QR generation |
| **Speech & Audio** | `speech_to_text: ^7.4.0`, `flutter_tts: ^4.2.2` | Hands-free voice commands & audible countdown guidance |
| **Clinical Export** | `pdf: ^3.13.0`, `printing: ^5.15.0` | Physician-ready adherence reports & data exports |
| **Adherence Charts** | `fl_chart: ^1.2.0` | PDC/MPR compliance tracking & intake history graphs |

---

## 🔒 Privacy & Security-First Architecture

* **100% On-Device Processing**: Zero health records, prescription photos, or dosage logs ever leave the user's phone.
* **No Third-Party Telemetry**: Zero analytics SDKs, trackers, or commercial profiling.
* **Zero Hardcoded Secrets**: Secrets and credentials are exclusively injected via secure runtime environments.
* **Fail-Closed Security**: Authentication checks and security constraints fail closed by default.
* **GDPR & HIPAA Data Sovereignty**: One-tap permanent data purge (`purgeAllData`) adhering to GDPR Article 17 "Right to be Forgotten".

---

## 🚀 Getting Started

### Prerequisites
* **Flutter SDK**: `3.47.x` or higher
* **Java Development Kit**: Microsoft OpenJDK 17 LTS
* **Android SDK**: API Level 37 (`android-37`)
* **Gradle**: `8.11.1` (bundled via `gradlew`)
* **Android Gradle Plugin (AGP)**: `8.9.1`

### Build & Run Instructions

```bash
# 1. Clone the repository
git clone https://github.com/<YOUR_ORGANIZATION>/<YOUR_REPOSITORY>.git
cd <YOUR_REPOSITORY>

# 2. Fetch dependencies
flutter pub get

# 3. Verify static analysis (Zero errors)
dart analyze lib/

# 4. Run automated clinical and widget test suite
flutter test test/prescription_understanding_test.dart test/eye_hospital_prescriptions_test.dart test/medicine_alarm_dialog_test.dart test/visuals_and_companion_unit_test.dart

# 5. Launch in debug mode
flutter run

# 6. Build production Release APK
flutter build apk --release
```

The compiled release APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Automated Test Suite

MediMind Pro features an exhaustive automated test suite covering clinical edge cases, prescription parsing, and UI resilience:

```bash
# Run all tests
flutter test
```

Key test suites:
* `test/prescription_understanding_test.dart`: Validates matrix notation parsing, Latin sigs, washout alerts, and Levenshtein fuzzy matching.
* `test/eye_hospital_prescriptions_test.dart`: Validates 8 post-operative clinical regimens across Cataract, Glaucoma, Cornea, Refractive, Retina, and Orbit care.
* `test/medicine_alarm_dialog_test.dart`: Validates heads-up alarm dialog rendering, 1-tap dose logging, and snooze mechanics.
* `test/visuals_and_companion_unit_test.dart`: Validates mascot character rendering across all moods and outfit variations.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
