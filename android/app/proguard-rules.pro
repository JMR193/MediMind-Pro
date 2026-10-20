# ProGuard and R8 rules for MediMind Pro

# Flutter core
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Local Notifications (Reboot & Alarm Persistence)
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.work.** { *; }

# Flutter Secure Storage & Crypto
-keep class androidx.security.crypto.** { *; }

# Camera & Lifecycle
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
-dontwarn androidx.camera.video.**
-dontwarn androidx.camera.core.**

# Google ML Kit OCR and vision models
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.**

# Google Play Core deferred components / split install
-dontwarn com.google.android.play.core.**

# Java Time & Desugaring
-dontwarn java.time.**

# Keep annotations, signatures, and inner classes for models
-keepattributes *Annotation*,EnclosingMethod,Signature,InnerClasses
