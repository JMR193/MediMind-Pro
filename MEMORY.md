# MEMORY.md — MediMind Pro Architecture & Project Memory

## 1. Project Overview
- **Name**: MediMind Pro (Clinical Edition)
- **Tagline**: The Intelligent, Offline-First Medication & Ophthalmic Clinical Companion
- **Framework**: Flutter (Dart 3.13.2+ / SDK ^3.13.2)
- **Primary OS Target**: Android (Compile SDK 37, Min SDK 24, Target SDK 35/37)

## 2. Tech Stack & Key Dependencies
- **State Management**: provider: ^6.1.5+1
- **Local Persistence**: shared_preferences: ^2.5.5, flutter_secure_storage: ^11.0.0
- **Notifications & Alarms**: flutter_local_notifications: ^22.3.0, timezone: ^0.11.1, permission_handler: ^13.0.2
- **OCR & Computer Vision**: google_mlkit_text_recognition: ^0.17.1, image_picker: ^1.2.3
- **Offline AI & Speech**: speech_to_text: ^7.4.0, flutter_tts: ^4.2.2, Custom On-Device Clinical Decision Engine
- **First Responder & Sharing**: qr_flutter: ^4.1.0, share_plus: ^13.3.0
- **Reports & Visuals**: fl_chart: ^1.2.0, pdf: ^3.13.0, printing: ^5.15.0, table_calendar: ^3.2.1
- **Animations & UI**: dynamic_color: ^1.7.0, flutter_animate: ^4.5.2, lottie: ^3.5.1

## 3. Toolchain & Build Configuration
- **Java**: Microsoft OpenJDK 17 LTS (C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot)
- **Gradle**: Wrapper gradle-8.11.1-all.zip
- **Android Gradle Plugin (AGP)**: 8.9.1 in android/settings.gradle.kts
- **Kotlin**: 2.2.20 in android/settings.gradle.kts
- **Platform SDK**: Configured for android-37 with valid source.properties and schema v3 package.xml.
- **R8 / ProGuard**:
  - Configured in android/app/proguard-rules.pro with -dontwarn com.google.mlkit.vision.text.** and -dontwarn com.google.android.play.core.**.

## 4. Key Architectural Patterns & Modules
1. **Repository Pattern**:
   - MedicationRepository (lib/data/repositories/medication_repository.dart): Central single source of truth managing medications, dose logs, opened bottle shelf-life (28-day ophthalmic safety rule), stock decrement, symptom logs, and user profile.
2. **Notification Service**:
   - NotificationService (lib/data/services/notification_service.dart): Exact alarms, auto-cleanup of pending notifications matching medication ID, channel configuration for high-priority heads-up alarms with lock screen wake.
3. **OEM Battery & Reliability Engine**:
   - DeviceIntegrationService (lib/data/services/device_integration_service.dart): Auto-detects Samsung, Vivo, Xiaomi, Oppo, OnePlus, Pixel, iOS. Quantifies background alarm reliability (10-100%) and provides OEM step-by-step bypass guides.
4. **Clinical Decision Modules**:
   - Interaction Service (lib/data/services/interaction_service.dart): Cross-checks multi-drug interactions, food/drink conflicts (grapefruit, dairy, caffeine, alcohol), and disease contraindications (asthma, peptic ulcers, bradycardia, glaucoma).
   - Smart Refill & Inventory (lib/ui/features/medications/refill_tracker_screen.dart): Burn-rate depletion forecasting, visual battery gauges, 1-tap WhatsApp/SMS/Share order dispatch.
   - Emergency Medical ID (lib/ui/features/profile/emergency_medical_id_screen.dart): First-responder screen with offline scannable QR code (QrImageView) and 1-tap ER speed dial.
5. **Adaptive Design System**:
   - UiDesignStyle (Apple iOS 18 Glass, Samsung One UI 7, Material 3 Adaptive).
   - Dynamic Island interactive status pill (DynamicIslandPill).
