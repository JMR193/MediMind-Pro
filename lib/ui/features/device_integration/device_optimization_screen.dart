import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/device_integration_service.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/one_ui_widgets.dart';
import '../../core/theme.dart';

class DeviceOptimizationScreen extends StatefulWidget {
  const DeviceOptimizationScreen({super.key});

  @override
  State<DeviceOptimizationScreen> createState() => _DeviceOptimizationScreenState();
}

class _DeviceOptimizationScreenState extends State<DeviceOptimizationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceIntegrationService>().checkStatuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Integration & Reliability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
            onPressed: () {
              AppleGlassDecorations.lightHaptic();
              context.read<DeviceIntegrationService>().checkStatuses();
            },
          ),
        ],
      ),
      body: Consumer<DeviceIntegrationService>(
        builder: (context, service, _) {
          final guide = service.getGuide(service.detectedBrand);
          final score = service.reliabilityScore;
          final isPerfect = score >= 95;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Health Score Gauge Card
              _buildReliabilityScoreCard(context, service, score, isPerfect),
              const SizedBox(height: 16),

              // Brand Switcher / Detected Model
              _buildBrandSelectorCard(context, service),
              const SizedBox(height: 16),

              // Core Android System Checklist
              _buildPermissionsChecklist(context, service),
              const SizedBox(height: 16),

              // Brand-specific Step-by-Step Instructions
              _buildBrandSpecificGuide(context, service, guide),
              const SizedBox(height: 24),

              // System Settings Deep Link Action
              FilledButton.icon(
                onPressed: () {
                  AppleGlassDecorations.mediumHaptic();
                  service.openAppSettingsMenu();
                },
                icon: const Icon(Icons.settings_suggest_outlined),
                label: const Text('Open Device Settings for MediMind Pro'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReliabilityScoreCard(
    BuildContext context,
    DeviceIntegrationService service,
    int score,
    bool isPerfect,
  ) {
    final statusColor = isPerfect
        ? MediMindTheme.successGreen
        : score >= 60
            ? MediMindTheme.warningOrange
            : MediMindTheme.alertRed;

    return OneUiWidgets.squircleCard(
      context: context,
      backgroundColor: statusColor.withAlpha(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPerfect ? 'Guaranteed Alarm Delivery' : 'Background Alarms at Risk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPerfect
                          ? 'All OEM battery limits bypassed. Reminders will ring reliably.'
                          : 'Aggressive battery management may silence alarms while your phone is sleeping.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandSelectorCard(
    BuildContext context,
    DeviceIntegrationService service,
  ) {
    return OneUiWidgets.squircleCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR DEVICE BRAND',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Auto-Detected',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DeviceBrand>(
            initialValue: service.detectedBrand,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              prefixIcon: const Icon(Icons.smartphone_rounded),
            ),
            items: const [
              DropdownMenuItem(value: DeviceBrand.samsung, child: Text('Samsung Galaxy (One UI)')),
              DropdownMenuItem(value: DeviceBrand.vivo, child: Text('Vivo & iQOO (Funtouch/OriginOS)')),
              DropdownMenuItem(value: DeviceBrand.xiaomi, child: Text('Xiaomi / Redmi / POCO (HyperOS)')),
              DropdownMenuItem(value: DeviceBrand.oppoRealme, child: Text('OPPO & Realme (ColorOS)')),
              DropdownMenuItem(value: DeviceBrand.onePlus, child: Text('OnePlus (OxygenOS)')),
              DropdownMenuItem(value: DeviceBrand.apple, child: Text('Apple iPhone (iOS 17/18)')),
              DropdownMenuItem(value: DeviceBrand.googlePixel, child: Text('Google Pixel (Stock Android)')),
              DropdownMenuItem(value: DeviceBrand.other, child: Text('Other Android Device')),
            ],
            onChanged: (brand) {
              if (brand != null) {
                AppleGlassDecorations.lightHaptic();
                service.setBrand(brand);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsChecklist(
    BuildContext context,
    DeviceIntegrationService service,
  ) {
    return OneUiWidgets.squircleCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM RELIABILITY CHECKLIST',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckItem(
            context,
            title: 'Exact Alarms & Reminders',
            subtitle: 'Required for to-the-minute dose precision',
            isGranted: service.isExactAlarmGranted,
            onRequest: () => service.requestExactAlarmPermission(),
          ),
          const Divider(height: 20),
          _buildCheckItem(
            context,
            title: 'Battery Optimization Exemption',
            subtitle: 'Prevents phone OS from killing alarms when idle',
            isGranted: service.isBatteryOptimizationIgnored,
            onRequest: () => service.requestBatteryOptimizationBypass(),
          ),
          const Divider(height: 20),
          _buildCheckItem(
            context,
            title: 'Notification & Critical Alerts',
            subtitle: 'Required to show heads-up banners & ring alarms',
            isGranted: service.isNotificationGranted,
            onRequest: () => service.requestNotificationPermission(),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(
    BuildContext context,
    {
      required String title,
      required String subtitle,
      required bool isGranted,
      required VoidCallback onRequest,
    }
  ) {
    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
          color: isGranted ? MediMindTheme.successGreen : MediMindTheme.warningOrange,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!isGranted)
          TextButton(
            onPressed: () {
              AppleGlassDecorations.mediumHaptic();
              onRequest();
            },
            child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildBrandSpecificGuide(
    BuildContext context,
    DeviceIntegrationService service,
    OemOptimizationGuide guide,
  ) {
    return OneUiWidgets.squircleCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${guide.brandName} Optimization Guide',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      guide.osName,
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              guide.whyNeeded,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Recommended Steps for 100% Alarm Reliability:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...guide.steps.map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
