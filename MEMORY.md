# MEMORY.md — MediMind Pro Architecture & Project Memory

## 1. Project Overview
- **Name**: MediMind Pro (Clinical & Research 2.0 Edition)
- **Tagline**: The Intelligent, Offline-First Medication & Ophthalmic Clinical Companion
- **Framework**: Flutter (Dart 3.13.2+ / SDK ^3.13.2)
- **Primary OS Target**: Android (Compile SDK 37, Min SDK 24, Target SDK 35/37)

## 2. Tech Stack & Key Dependencies
- **State Management**: `provider: ^6.1.5+1`
- **Local Persistence**: `shared_preferences: ^2.5.5`, `flutter_secure_storage: ^11.0.0`
- **Notifications & Alarms**: `flutter_local_notifications: ^22.3.0`, `timezone: ^0.11.1`, `permission_handler: ^13.0.2`
- **OCR & Computer Vision**: `google_mlkit_text_recognition: ^0.17.1`, `image_picker: ^1.2.3`
- **Offline AI & Speech**: `speech_to_text: ^7.4.0`, `flutter_tts: ^4.2.2`, Custom On-Device Clinical Decision Engine
- **First Responder & Sharing**: `qr_flutter: ^4.1.0`, `share_plus: ^13.3.0`
- **Reports & Visuals**: `fl_chart: ^1.2.0`, `pdf: ^3.13.0`, `printing: ^5.15.0`, `table_calendar: ^3.2.1`
- **Animations & UI**: `dynamic_color: ^1.7.0`, `flutter_animate: ^4.5.2`, `lottie: ^3.5.1`

## 3. Toolchain & Build Configuration
- **Java**: Microsoft OpenJDK 17 LTS (`C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot`)
- **Gradle**: Wrapper `gradle-8.11.1-all.zip`
- **Android Gradle Plugin (AGP)**: `8.9.1` in `android/settings.gradle.kts`
- **Kotlin**: `2.2.20` in `android/settings.gradle.kts`
- **Platform SDK**: Configured for `android-37` with valid `source.properties` and schema v3 `package.xml`.
- **R8 / ProGuard**:
  - Configured in `android/app/proguard-rules.pro` with `-dontwarn com.google.mlkit.vision.text.**` and `-dontwarn com.google.android.play.core.**`.

## 4. Multi-Perspective Architectural Modules

### A. Doctor & Clinical Specialist Layer
1. **Interactive Punctal Occlusion Engine (`PunctalOcclusionScreen`)**:
   - 60s anatomical countdown with pulsing circle, auditory cue, and vibration to prevent systemic absorption of beta-blockers/glaucoma drops.
2. **Ophthalmic Formulation Hierarchy (`OphthalmicFormulation`)**:
   - Strictly sequences Solutions $\rightarrow$ Suspensions $\rightarrow$ Emulsions $\rightarrow$ Gels $\rightarrow$ Ointments with a mandatory 5-minute spacing timer.
3. **Clinical Tapering & Titration Protocols (`ClinicalTaperPlan`, `TaperingScheduleScreen`)**:
   - Step-down regimens (e.g. Post-Cataract Prednisolone 4x/d $\rightarrow$ 3x/d $\rightarrow$ 2x/d $\rightarrow$ 1x/d), automatically advancing on dose logging.
4. **Pharmacological Missed-Dose Decision Algorithm (`evaluateMissedDose`)**:
   - Implements half-interval rule with drug-specific thresholds (Warfarin 6h limit, Glaucoma drops 3h limit, Levothyroxine fasting instructions).
5. **AGS Beers Criteria 2023 Senior Pharmacovigilance (`checkBeersCriteria`)**:
   - Real-time screening for anticholinergics, sedatives, chronic NSAIDs, and long-acting sulfonylureas in patients aged 65+.

### B. Researcher & Epidemiologist Layer
1. **ISPOR / WHO Adherence Biomarkers (`ChronotherapyResearchService`)**:
   - **PDC (Proportion of Days Covered)**: International benchmark for chronic therapy adherence ($\ge 80\%$).
   - **MPR (Medication Possession Ratio)**: Quantity-based adherence calculation.
   - **Circadian Timing Drift Index**: Mean minutes deviation from scheduled biological clock times.
   - **Morning vs. Evening vs. Weekend compliance rates**.
2. **De-identified Research CSV Dataset Export**:
   - Standardized format for longitudinal adherence research.

### C. Patient, Senior & Caregiver Layer
1. **Digital 4-Slot Daily Pillbox (`DigitalPillboxScreen`)**:
   - Morning (☀️ 06:00–11:59), Noon (🌤️ 12:00–16:59), Evening (🌅 17:00–20:59), Bedtime (🌙 21:00–05:59).
   - 1-tap "Take All" batch logging with auditory confirmation.
2. **Senior & Accessibility Mode (`SeniorModeWidget`, `SeniorModeHelper`)**:
   - 64px+ oversized touch targets, maximum contrast, and automatic TTS slow-rate voice guidance.
3. **Emergency Medical ID (`EmergencyMedicalIdScreen`)**:
   - Offline scannable QR code containing allergies, blood group, ICE contacts, and active medications.

### D. Entrepreneur & Platform Scalability Layer
1. **Multi-Patient / Family Profile Switcher (`FamilyProfilesScreen`)**:
   - Isolated profiles for Self, Elderly Parents, Children, and Pets with zero data cross-contamination.
2. **Smart Refill & Inventory Automation (`RefillTrackerScreen`)**:
   - Burn-rate forecasting, stock battery gauges, and 1-tap WhatsApp/Pharmacy order dispatch.
3. **Caregiver Telehealth Digest (`CaregiverScreen`)**:
   - Automated miss-dose alerts and PDF adherence report sharing.

### E. Security, Regulatory & Architecture Enhancements (MediMind 2.0)
1. **Resilient Storage Engine (`ResilientStorageEngine`)**:
   - Structured JSON database engine with Write-Ahead Logging (WAL) and atomic `.tmp` replace commits.
   - Dual-persistence sync with `StorageService` for zero-corruption guarantee and crash recovery.
2. **Visual Pill & Drug Identifier (`PillIdentifierScreen`)**:
   - Multi-attribute filtering by shape, color, imprint, and scoring.
   - Dual search across active cabinet items and clinical drug reference library.
3. **Quick Response (QR) Regimen Hub (`QrCodeShareScreen`)**:
   - High-density JSON QR code generator for complete medication schedule & patient profile sharing.
   - Camera/clipboard prescription import with automated pre-screening for drug-drug interactions (DDI).
4. **HIPAA & GDPR Compliance Center (`ComplianceScreen`)**:
   - Zero-cloud, 100% on-device AES-256 storage guarantee.
   - GDPR Article 17 "Right to be Forgotten" one-tap permanent storage purge (`purgeAllData`).
   - WCAG 2.1 Level AA real-time accessibility contrast and touch target validator.
5. **Foreground In-App Alert System (`InAppNotificationOverlay`)**:
   - Sliding glass overlay for real-time notification broadcast when app is active.
   - Dedicated ophthalmic drop spacing countdown alerts and punctal occlusion guidance.

### F. MediLink Connected Healthcare & Dual-Mode System (Behance Case Study 255958521)
1. **Dual-Mode Operational Paradigm**:
   - **User Mode (Patient)**: Calm Blue (`#4A90E2` / Soft Blue `#CDE1FF`), focused on intuitive medication intake, visual schedule calendar, alarms, and emergency actions.
   - **Guardian Mode (Caregiver)**: Emerald Green (`#36A25D` / Soft Mint `#B2E6C1`), focused on remote monitoring, live adherence gauges, remote schedule management, and pharmacy replenishment.
2. **SOS Emergency Command Screen (`SosEmergencyScreen`)**:
   - 1-tap SOS trigger with 5s cancellable countdown to prevent false alarms.
   - Automated live GPS location dispatch and emergency contact notification.
   - Audible distress siren alarm toggle to alert nearby individuals in physical emergencies.
   - Speed-dial integration for local emergency dispatch (911/112) and primary caregivers.
3. **Stock-Out Alert & Refill Hub (`StockOutAlertScreen`)**:
   - Dedicated inventory crisis screen highlighting depleted and near-empty medications.
   - Automated 1-tap SMS & phone call dispatch with pre-filled replenishment requests to guardians.
   - High-density QR code prescription transmission for pharmacy counter presentation.
4. **Heads-Up Medication Alarm Dialog (`MedicineAlarmDialog`)**:
   - Animated ringing bell with clear high-contrast dosage and administration instructions.
   - Large tactile actions: `✓ Taken`, `⏰ Snooze 10 Min`, and `✕ Skip` (with skip-reason clinical tracking).
5. **Guardian Mode & Doorstep Pharmacy Delivery Hub (`GuardianDashboardScreen`)**:
   - Live patient adherence circular gauge with today's intake breakdown.
   - Remote medication schedule management and low-inventory reordering.
   - Integrated doorstep delivery hub supporting partner pharmacies (Apollo Pharmacy, Netmeds, Tata 1mg, MedPlus).
   - 20% savings badge and live 4-stage order tracker (`Order Placed -> Packed -> Out for Delivery -> Delivered`).

### G. 3D Visualizations, Emotional Mascot & Realistic Simulation Suite
1. **Procedural 3D Vector Mascot "Pip the MediBuddy" (`MediBuddyCharacter`)**:
   - 100% offline, zero-asset procedural vector mascot running at 60/120 FPS.
   - Dynamic emotional states: `happy`, `encouraging`, `celebrating` (with confetti), `sleeping` (with floating Zzz bubbles), and `dropletGuide`.
   - Interactivity: Eye blinking, touch-following pupil tracking, tap-to-bounce physics, and uplifting Text-to-Speech (TTS) voice encouragement.
   - Wardrobes: Doctor (stethoscope & reflector), Nurse (cross cap), Champion (gold medal), and Casual.
2. **Dashboard Companion Header (`CompanionCardWidget`)**:
   - Dynamic greeting and contextual health speech bubbles based on time of day and adherence score.
   - Interactive outfit cycling and direct 1-tap navigation to the 3D Visual Studio.
3. **Interactive 3D Medication Inspector (`Interactive3dPillViewer`)**:
   - Real-time Matrix4 3D perspective projection with dual-axis touch drag orbital rotation and turntable auto-spin.
   - Dynamic specular lighting and realistic shading across 4 pharmaceutical models:
     - Bicolor Gelatin Capsule (translucent cap with visible micro-pellets).
     - Scored Round Tablet (debossed break-line and strength imprints).
     - Diamond Chamfered Tablet (faceted polygonal pill).
     - Ophthalmic Dropper Bottle (translucent squeeze bottle with gravity-reacting sloshing liquid meniscus).
4. **Animated Fluid Hydration Wave Tracker (`AnimatedWaterWaveTracker`)**:
   - Dual-sine wave animated fluid simulation with rising micro-bubbles.
   - Clinical guidance for swallowing oral tablets with 200–250ml water to prevent esophageal ulceration.
5. **3D Ophthalmic Eye Drop Simulator (`Ophthalmic3dDropSimulator`)**:
   - 3D perspective simulated eye cornea and dropper bottle.
   - Surface tension drop formation, detachment drip, and corneal tear-film dispersion ripples.
   - Integrated 60-second punctal occlusion guidance.
6. **3D Visual Studio & Pip Laboratory (`VisualLabScreen`)**:
   - 3-tab interactive laboratory combining the 3D Pill Inspector, MediBuddy Studio, and Fluid & Eye Drop Simulators.
