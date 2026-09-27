import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple iOS 18-inspired frosted glass styling and Cupertino tactile haptics
class AppleGlassDecorations {
  /// Trigger subtle tactile click (iOS / Samsung haptic engine)
  static void lightHaptic() {
    HapticFeedback.selectionClick();
  }

  /// Trigger medium confirmation haptic
  static void mediumHaptic() {
    HapticFeedback.mediumImpact();
  }

  /// Trigger warning / alert haptic
  static void heavyHaptic() {
    HapticFeedback.heavyImpact();
  }

  /// Frosted liquid glass card container
  static Widget glassCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 6),
    double borderRadius = 22.0,
    Color? tintColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTint = isDark
        ? Colors.white.withAlpha(20)
        : Colors.white.withAlpha(180);
    final borderColor = isDark
        ? Colors.white.withAlpha(35)
        : Colors.white.withAlpha(220);

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tintColor ?? defaultTint,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Padding(
        padding: margin,
        child: InkWell(
          onTap: () {
            lightHaptic();
            onTap();
          },
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return Padding(
      padding: margin,
      child: content,
    );
  }

  /// Frosted glass box decoration for custom container styling
  static BoxDecoration frostedGlassBox({
    Color color = Colors.white,
    double opacity = 0.85,
    double borderRadius = 18.0,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round()),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withAlpha(80),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Sleek iOS 18 pill button with frosted blur and spring scale
  static Widget glassPillButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          mediumHaptic();
          onPressed();
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isPrimary
                ? activeColor
                : activeColor.withAlpha(30),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isPrimary
                  ? activeColor
                  : activeColor.withAlpha(80),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isPrimary ? Colors.white : activeColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : activeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
