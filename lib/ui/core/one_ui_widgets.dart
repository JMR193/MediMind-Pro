import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'apple_glass_decorations.dart';

/// Samsung One UI 6/7 Ergonomic One-Handed Layout and UI Elements
class OneUiWidgets {
  /// One UI Reachability Header with distinct viewing area (top) and large typography
  static Widget reachabilityHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    Widget? trailing,
    double minHeight = 110,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Samsung One UI Squircle Card (26px radius)
  static Widget squircleCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 6),
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 35 : 12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin,
        child: InkWell(
          onTap: () {
            AppleGlassDecorations.lightHaptic();
            onTap();
          },
          borderRadius: BorderRadius.circular(26),
          child: content,
        ),
      );
    }

    return Padding(
      padding: margin,
      child: content,
    );
  }

  /// One UI Informational Banner Card
  static Widget bannerCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    Color? accentColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;

    return squircleCard(
      context: context,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(160),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Samsung One UI Quick Settings Pill Toggle
  static Widget quickSettingsPill({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = activeColor ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppleGlassDecorations.mediumHaptic();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? color
                : isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? color
                  : isDark
                      ? Colors.white.withAlpha(20)
                      : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? Colors.white
                    : isDark
                        ? Colors.white70
                        : const Color(0xFF475569),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : isDark
                          ? Colors.white
                          : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Samsung Edge Lighting pulsating animation for critical alarms
  static Widget edgeLightingOverlay({required Widget child, bool isTriggered = true}) {
    if (!isTriggered) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF38BDF8), width: 3.5),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).boxShadow(
                  begin: const BoxShadow(
                    color: Color(0x6638BDF8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                  end: const BoxShadow(
                    color: Color(0xCC38BDF8),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                  duration: 800.ms,
                ),
          ),
        ),
      ],
    );
  }
}
