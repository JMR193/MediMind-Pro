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

### H. Pre-Configured Clinical AI & Behavioral Machine Learning Suite (Neuro-Symbolic)
1. **Chronotherapy Circadian Alignment Engine (`ClinicalExpertAiService`)**:
   - Grounded in circadian chronobiology for statins (bedtime lipogenesis peak), PPIs (morning acid pump stimulation), glaucoma prostaglandins (bedtime IOP surge mitigation), corticosteroids (morning cortisol synchrony), and antihypertensives (non-dipper nocturnal conversion).
   - Generates patient Circadian Synchronization Score and provides 1-tap regimen realignment.
2. **Pharmacokinetic Half-Interval Rescue Calculator**:
   - Evaluates whether a missed dose can be safely taken based on $T_{\text{elapsed}} / T_{\text{interval}} \le 0.50$.
   - Strict clinical override windows: DOACs/Warfarin (6h strict max limit), Glaucoma drops (3h limit), Levothyroxine (fasting override).
3. **Medical Prescription Latin 'Sig' Shorthand NLP Decrypter**:
   - Instant deterministic decryption of doctor shorthand (`PO TID PC`, `1 GTT OS QHS`, `2 PUFF Q4H PRN`) into structured dosage amounts, units, frequencies, and scheduled times.
4. **Behavioral Machine Learning Engine (`BehavioralMlEngine`)**:
   - **Adherence Risk Forecaster**: Statistical model identifying high drop-off days (e.g., weekends) and vulnerable times of day.
   - **Adaptive Circadian Timing Learner**: Analyzes mean drift ($\Delta t$) and standard deviation ($\sigma$) to recommend alarm window shifts matching actual patient routines.
   - **Cognitive Latency Drift & Anomaly Detector**: Exponential Moving Average (EMA) and Z-score tracking of response latency to alert caregivers of early cognitive decline or regimen burnout.
5. **Smart Chronotherapy & AI Advisor Screen (`SmartChronotherapyAdvisorScreen`)**:
   - Scaled into a unified 5-tab Clinical Intelligence Suite: Circadian AI, Digital Twin PK, Food & Diet AI, Behavioral ML, and Latin Sig Decrypter.

### I. Digital Twin Pharmacokinetics (PK) & Drug-Food-Nutrient AI Architecture
1. **Mathematical Pharmacokinetic Simulator (`PharmacokineticSimulatorService`)**:
   - 1-Compartment extravascular open Bateman function:
     $$C(t) = \frac{F \cdot D \cdot k_a}{V_d (k_a - k_e)} (e^{-k_e t} - e^{-k_a t})$$
   - Linear superposition multi-dose accumulation engine calculating steady-state peak ($C_{\max, ss}$), trough ($C_{\min, ss}$), and percentage of time in the therapeutic window ($MEC \le C \le MTC$).
   - Curated pharmacokinetic constants for 9 clinical drug families (Atorvastatin, Amlodipine, Metoprolol, Metformin, Warfarin, Levothyroxine, Ciprofloxacin, Timolol, Lisinopril) + heuristic fallbacks.
   - Interactive "What-If" scenario simulator (Normal, 4h Late, Missed Dose, Accidental Double-Dose).
2. **Deterministic Drug-Food-Nutrient AI Engine (`DrugFoodInteractionAiService`)**:
   - Knowledge base spanning CYP3A4 irreversible inhibition (Grapefruit furanocoumarins), multivalent cation chelation (Dairy/Calcium with fluoroquinolones and tetracyclines), pharmacodynamic antagonism (Vitamin K greens vs Warfarin), hyperkalemia synergism (ACEi/ARBs + high potassium), alcohol CNS depression & disulfiram-like reactions (Metronidazole), tyramine pressor crises (MAOIs), and protein transport competition (Levodopa).
   - Cabinet-wide automated screening with actionable spacing intervals (e.g. 2h/4h buffers) and instant interactive food search query console.
3. **Interactive Visual Modules**:
   - `DigitalTwinPkCard`: High-precision custom canvas chart rendering continuous blood plasma concentration curves, shaded therapeutic window (MEC-MTC), MTC toxic threshold lines, and live time indicators.
   - `FoodInteractionRadarCard`: Search bar with quick food query chips (`🍊 Grapefruit`, `🥛 Milk`, `🥬 Spinach`, etc.) and severity classification badges (`CONTRAINDICATED`, `MAJOR RISK`, `MODERATE`).
   - Complete unit test coverage in `test/drug_food_and_pk_test.dart` and `test/clinical_ai_and_chrono_test.dart`.

### J. AI Health Coach, Telemetry, Daily Tasks, Academy & Check-In Suite (`AiAssistantScreen`)
1. **Multilingual Offline Conversational AI Tutor (`AiAssistantService`)**:
   - 15 languages, on-device NLP, intent detection, auto-speech TTS voice guidance, prescription parsing from text or voice.
2. **Dual-Perspective Clinical Telemetry & Chart Analytics (`ChartAssistantView` & `AiTelemetryAnalyticsView`)**:
   - Pharmacological timing jitter ($\sigma_{\text{jitter}}$), FlChart linear regression, compliance forecasting, dose distribution donut.
   - AI assistant consultation telemetry, query topic radar, on-device edge latency sparkline ($\sim 12$ ms), zero-cloud HIPAA/GDPR audit ledger.
3. **Interactive Daily Clinical Tasks & 60s Punctal Occlusion Coach**:
   - Automated routine generator, haptic 60s countdown timer with anatomical cues for nasolacrimal duct closure, 20-20-20 cornea rest timer.
4. **Ophthalmology & Pharmacology Academy & 3D Interactive Flashcards**:
   - Micro-courses on Punctal Occlusion, 5-Minute Spacing Rule, 28-Day Bottle Expiration, and Glaucoma Chronotherapy.
   - Interactive flip flashcards with 3D animation, self-testing, and real-time telemetry recording of mastery score.
5. **Clinical Symptom Triage & Red-Flag Escalation Check-In**:
   - Visual 0-10 Ocular Pain/Discomfort slider with dynamic clinical severity tagging (`None`, `Mild Gritty`, `Moderate Burning`, `Severe Pain`, `Emergency`).
   - Affected eye selector (`Left (OS)`, `Right (OD)`, `Both (OU)`).
   - Acute clinical red-flag banner for closed-angle glaucoma symptoms with 1-tap diary logging directly into `MedicationRepository`.

### K. Smartwatch & Wearable Companion Suite (Wear OS & watchOS)
1. **Hardware Smartwatch Simulator & Live Sync Engine (`WearableSyncService`, `WearableCompanionScreen`)**:
   - Hardware watch form-factors: Wear OS Circular (Galaxy/Pixel Watch 450x450) and Apple Watch Rounded Rectangle (410x502).
   - 3 interactive watchface modes:
     - Mode 1: Next-Dose Wrist Tile with countdown timer, medication color accent, and direct 1-tap `✓ Taken` / `⏰ 10m` snooze actions.
     - Mode 2: 60-Second Punctal Occlusion Wrist Coach with circular countdown ring, play/pause controls, and haptic pulses every 10 seconds.
     - Mode 3: Live Circular Adherence Rings showing today's intake progress percentage.
   - Built-in tactile wrist haptic feedback engine (`subtleTick`, `gentlePulse`, `strongAlert`, `emergencyStaccato`).
   - Sync bridge payload compiler with zero cloud leakage, preserving total offline privacy.

### L. 10x Global Patient Safety & Universal Travel Suite
1. **Circadian Travel & Jet-Lag Dose Shifter (`CircadianTravelService`, `TravelDoseShifterScreen`)**:
   - Solves the international timezone gap: calculates progressive 1.5h to 2h/day circadian phase shift protocols between origin and destination timezones.
   - Narrow Therapeutic Index drug detection (Warfarin, Tacrolimus, Insulin, Glaucoma drops) with strict conservative shifting to prevent lethal drug accumulation or subtherapeutic troughs.
   - Global timezone registry spanning US, Europe, India, UAE, SE Asia, Japan, Australia, and New Zealand.
   - In-flight safety rules: cabin pressure dropper precautions, insulin cold-chain integrity, and TSA liquid exemptions.
2. **"Scan-Before-Swallow" / "Verify-Before-Instill" Safety Scanner (`MedicationSafetyScannerScreen`)**:
   - Camera reticle optical viewfinder with active laser sweep and torch control.
   - Real-time dose verification: matches scanned vial label against the patient's currently due scheduled dose.
   - Emerald Green Verified Safe Shield vs. Blaring Red Hazard Alarm: *"⚠️ DANGER: WRONG MEDICATION! Scanned bottle does NOT match scheduled dose. DO NOT TAKE!"*
   - Interactive testing rig for instant simulation of correct and wrong vial scans.
3. **Universal Multilingual Paramedic ICE (In Case of Emergency) HUD (`UniversalEmergencyHudScreen`)**:
   - Instant 1-tap translation into 10 world languages (English, Spanish, Hindi, French, Mandarin, Japanese, Arabic, German, Russian, Portuguese).
   - Life-saving red-flag alert banners: Anticoagulant warning (Warfarin/DOACs) to prevent fatal hemorrhage from thrombolytics (tPA), severe allergy flags, and blood group tag.
   - Dynamic worldwide emergency dispatch speed-dial: switches between 911 (US/Canada), 112 (Europe/India), 999 (UK), 119 (Japan), and 000 (Australia).
   - Scannable high-density QR medical passport readable by any paramedic scanner without internet.
4. **Smart Refill & Weekend Refill Cliff Forecaster (`RefillForecastScreen`)**:
   - Daily burn-rate calculations predicting exact depletion date and weekday.
   - "Weekend Refill Cliff" warning highlighting medications running out on Saturdays or Sundays when pharmacies and clinics are closed.
   - 1-tap pre-formatted WhatsApp/SMS prescription replenishment request generator.
5. **Full Unit Test Verification**:
   - `test/global_safety_and_travel_test.dart` passes with 100% green checkmarks across circadian phase shifts, narrow therapeutic index detections, and timezone calculations.

### M. 3D Visual Suite, Procedural Mascot & Realistic Pharmaceutical Assets
1. **Pervasive MediBuddy Pip Integration**:
   - Empty State: Doctor Pip in `medications_list_screen.dart` with custom speech bubbles and animated bounce.
   - Adherence Streak: Champion Pip with gold medal in `streak_screen.dart` celebrating streaks with confetti.
   - Ringing Alarm: Doctor/Droplet Guide Pip in `medicine_alarm_dialog.dart` comforting patients alongside the ringing bell.
   - Ophthalmic Coach: Droplet Guide Pip in `punctal_occlusion_screen.dart` guiding patients through 60s nasolacrimal compression.
2. **Realistic 3D Medicine Card (`Realistic3dMedicineCard`)**:
   - Procedural 2.5D/3D custom canvas shaders rendering photorealistic pharmaceutical assets without external 3D files.
   - Capsule: Translucent bottom half with visible micro-pellets, specular glare, and separation rim.
   - Scored Tablet: Chamfered beveled rim, radial illumination gradient, and debossed break lines.
   - Dropper Bottle: Translucent glass body with dual-sine sloshing fluid wave physics and forming tip teardrop.
   - Interactive micro-tilt on drag (`Matrix4` 3D perspective projection).
   - Embedded into `VisualLabScreen` with real-time modal inspection (`Interactive3dPillViewer`).
3. **Automated Verification**:
   - Complete test suite in `test/realistic_3d_visuals_test.dart` covering 3D cards, viewport rendering, and character moods.

### N. Global Research, Enterprise PRD & Systems Architecture Milestone
1. **Authoritative `PRD.md` Created**:
   - 20 Functional Requirements (FR-01 to FR-20) covering Regimen Management, 4-Slot Pillbox, Ophthalmic Spacing, Digital Twin PK, Chronotherapy, Beers Criteria, Travel Dose Shifter, Safety Scanner, ICE Paramedic HUD, Refill Cliff Forecaster, and 3D Visuals.
   - 6 Key Clinical & Patient Personas (Polypharmacy Senior, Family Guardian, Global Traveler, Specialist Physician, Paramedic, Pharmacist).
   - Regulatory alignment with FDA SaMD Class I (CDS Exemption), HIPAA 45 CFR § 164, GDPR Article 17, and WCAG 2.1 Level AAA.
2. **Authoritative `ARCHITECTURE.md` Created**:
   - Systems topology combining Clean Architecture, Unidirectional Data Flow, and an Offline-First Local Vault.
   - Resilient Storage Engine featuring Write-Ahead Logging (WAL) and atomic `.tmp` replace file commits.
   - HL7 FHIR R4 standard schema compliance (`MedicationRequest`, `MedicationStatement`, `MedicationAdministration`).
   - Deep mathematical formulations for Bateman 1-Compartment PK Accumulation ODEs, ISPOR PDC (CMA-3) adherence, and trans-meridian circadian phase shifts.
   - Background exact alarm dispatch bypassing Android 14 Doze mode and OEM task killers (Samsung, Xiaomi, Huawei).
3. **Static Analysis & Code Quality Certified**:
   - All legacy and newly introduced type issues, null safety edge cases, and unused directives resolved (`dart analyze lib/` verified with 0 errors).

