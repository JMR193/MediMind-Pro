import 'package:flutter/material.dart';
import '../../domain/models/medication.dart';
import '../../domain/models/medication_log.dart';

/// Utility to get icon data for a given iconName string
IconData getMedicationIcon(String iconName) {
  switch (iconName) {
    case 'eye_drop':
      return Icons.remove_red_eye_outlined;
    case 'inhaler':
      return Icons.air_outlined;
    case 'syringe':
      return Icons.vaccines_outlined;
    case 'capsule':
      return Icons.medication_liquid_outlined;
    case 'liquid':
      return Icons.local_drink_outlined;
    case 'topical':
      return Icons.colorize_outlined;
    case 'nasal':
      return Icons.masks_outlined;
    default:
      return Icons.medication_outlined;
  }
}

/// Convert colorHex string like "#0284C7" to Flutter Color
Color hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

String dosageUnitLabel(DosageUnit unit) {
  switch (unit) {
    case DosageUnit.mg:
      return 'mg';
    case DosageUnit.ml:
      return 'mL';
    case DosageUnit.drops:
      return 'drop(s)';
    case DosageUnit.puffs:
      return 'puff(s)';
    case DosageUnit.units:
      return 'unit(s)';
    case DosageUnit.spray:
      return 'spray(s)';
    case DosageUnit.tablets:
      return 'tablet(s)';
    case DosageUnit.capsules:
      return 'capsule(s)';
    case DosageUnit.applyTopical:
      return 'application(s)';
  }
}

String adminInstructionLabel(AdminInstruction inst) {
  switch (inst) {
    case AdminInstruction.beforeMeal:
      return 'Before Meal';
    case AdminInstruction.withMeal:
      return 'With Meal';
    case AdminInstruction.afterMeal:
      return 'After Meal';
    case AdminInstruction.emptyStomach:
      return 'Empty Stomach';
    case AdminInstruction.atBedtime:
      return 'At Bedtime';
    case AdminInstruction.asNeeded:
      return 'As Needed (PRN)';
    case AdminInstruction.withFullGlassOfWater:
      return 'With Full Glass of Water';
  }
}

String medCategoryLabel(MedCategory cat) {
  switch (cat) {
    case MedCategory.oral:
      return 'Oral';
    case MedCategory.eyeDrop:
      return 'Eye Drop';
    case MedCategory.eyeOintment:
      return 'Eye Ointment';
    case MedCategory.inhaler:
      return 'Inhaler';
    case MedCategory.injectable:
      return 'Injectable';
    case MedCategory.topical:
      return 'Topical';
    case MedCategory.nasalSpray:
      return 'Nasal Spray';
    case MedCategory.other:
      return 'Other';
  }
}

Color logStatusColor(LogStatus status, [BuildContext? context]) {
  switch (status) {
    case LogStatus.taken:
      return const Color(0xFF16A34A);
    case LogStatus.skipped:
    case LogStatus.missed:
      return const Color(0xFFDC2626);
    case LogStatus.snoozed:
      return const Color(0xFFD97706);
    case LogStatus.delayed:
      return const Color(0xFF7C3AED);
  }
}

IconData logStatusIcon(LogStatus status) {
  switch (status) {
    case LogStatus.taken:
      return Icons.check_circle_outline;
    case LogStatus.skipped:
      return Icons.cancel_outlined;
    case LogStatus.missed:
      return Icons.error_outline;
    case LogStatus.snoozed:
      return Icons.snooze_outlined;
    case LogStatus.delayed:
      return Icons.access_time_outlined;
  }
}
