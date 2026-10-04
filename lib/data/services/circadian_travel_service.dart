import 'dart:math' as math;
import '../../domain/models/medication.dart';

/// Represents a timezone with UTC offset for travel calculations
class GlobalTimeZone {
  final String id;
  final String city;
  final String region;
  final double utcOffsetHours;
  final String flagEmoji;

  const GlobalTimeZone({
    required this.id,
    required this.city,
    required this.region,
    required this.utcOffsetHours,
    required this.flagEmoji,
  });

  static const List<GlobalTimeZone> majorTimeZones = [
    GlobalTimeZone(id: 'US/Pacific', city: 'Los Angeles / SF', region: 'USA (PST)', utcOffsetHours: -8.0, flagEmoji: '🇺🇸'),
    GlobalTimeZone(id: 'US/Mountain', city: 'Denver', region: 'USA (MST)', utcOffsetHours: -7.0, flagEmoji: '🇺🇸'),
    GlobalTimeZone(id: 'US/Central', city: 'Chicago', region: 'USA (CST)', utcOffsetHours: -6.0, flagEmoji: '🇺🇸'),
    GlobalTimeZone(id: 'US/Eastern', city: 'New York', region: 'USA (EST)', utcOffsetHours: -5.0, flagEmoji: '🇺🇸'),
    GlobalTimeZone(id: 'America/Sao_Paulo', city: 'São Paulo', region: 'Brazil (BRT)', utcOffsetHours: -3.0, flagEmoji: '🇧🇷'),
    GlobalTimeZone(id: 'UTC', city: 'London / UTC', region: 'UK (GMT)', utcOffsetHours: 0.0, flagEmoji: '🇬🇧'),
    GlobalTimeZone(id: 'Europe/Paris', city: 'Paris / Berlin / Rome', region: 'Europe (CET)', utcOffsetHours: 1.0, flagEmoji: '🇪🇺'),
    GlobalTimeZone(id: 'Europe/Athens', city: 'Athens / Cairo', region: 'East Europe (EET)', utcOffsetHours: 2.0, flagEmoji: '🇬🇷'),
    GlobalTimeZone(id: 'Asia/Dubai', city: 'Dubai', region: 'UAE (GST)', utcOffsetHours: 4.0, flagEmoji: '🇦🇪'),
    GlobalTimeZone(id: 'Asia/Kolkata', city: 'New Delhi / Mumbai', region: 'India (IST)', utcOffsetHours: 5.5, flagEmoji: '🇮🇳'),
    GlobalTimeZone(id: 'Asia/Bangkok', city: 'Bangkok / Jakarta', region: 'SE Asia (ICT)', utcOffsetHours: 7.0, flagEmoji: '🇹🇭'),
    GlobalTimeZone(id: 'Asia/Singapore', city: 'Singapore / Beijing', region: 'Asia (SGT/CST)', utcOffsetHours: 8.0, flagEmoji: '🇸🇬'),
    GlobalTimeZone(id: 'Asia/Tokyo', city: 'Tokyo / Seoul', region: 'Japan (JST)', utcOffsetHours: 9.0, flagEmoji: '🇯🇵'),
    GlobalTimeZone(id: 'Australia/Sydney', city: 'Sydney / Melbourne', region: 'Australia (AEST)', utcOffsetHours: 10.0, flagEmoji: '🇦🇺'),
    GlobalTimeZone(id: 'Pacific/Auckland', city: 'Auckland', region: 'New Zealand (NZST)', utcOffsetHours: 12.0, flagEmoji: '🇳🇿'),
  ];
}

/// Plan for an intermediate dosing step during multi-timezone flight & adaptation
class TravelDoseStep {
  final int dayNumber;
  final String dateLabel;
  final String scheduledTime;
  final double shiftHoursFromOrigin;
  final String clinicalInstruction;
  final bool isFlightDay;
  final bool isFinalDestination;

  const TravelDoseStep({
    required this.dayNumber,
    required this.dateLabel,
    required this.scheduledTime,
    required this.shiftHoursFromOrigin,
    required this.clinicalInstruction,
    this.isFlightDay = false,
    this.isFinalDestination = false,
  });
}

/// Full circadian travel itinerary shift report
class CircadianTravelPlan {
  final GlobalTimeZone origin;
  final GlobalTimeZone destination;
  final double netTimeDifferenceHours;
  final int recommendedTransitionDays;
  final List<TravelDoseStep> dosingSteps;
  final List<String> travelPrecautions;
  final bool isNarrowTherapeutic;

  const CircadianTravelPlan({
    required this.origin,
    required this.destination,
    required this.netTimeDifferenceHours,
    required this.recommendedTransitionDays,
    required this.dosingSteps,
    required this.travelPrecautions,
    this.isNarrowTherapeutic = false,
  });
}

/// Service that computes mathematically sound circadian transition regimens
/// to prevent dangerous underdosing or drug accumulation during international travel
class CircadianTravelService {
  /// Evaluates whether a medication has a narrow therapeutic index or strict timing requirements
  static bool isStrictTimingMedication(Medication med) {
    final name = med.name.toLowerCase();
    return name.contains('warfarin') ||
        name.contains('apixaban') ||
        name.contains('rivaroxaban') ||
        name.contains('tacrolimus') ||
        name.contains('cyclosporine') ||
        name.contains('levothyroxine') ||
        name.contains('insulin') ||
        name.contains('carbamazepine') ||
        name.contains('phenytoin') ||
        name.contains('lithium') ||
        name.contains('digoxin') ||
        med.isOphthalmic; // Eye drops need regular intraocular pressure control
  }

  /// Calculates the complete circadian shift plan
  CircadianTravelPlan calculateTravelPlan({
    required GlobalTimeZone origin,
    required GlobalTimeZone destination,
    required String originalTime, // e.g. "08:00"
    required DateTime departureDate,
    bool isNarrowTherapeutic = false,
  }) {
    final diffHours = destination.utcOffsetHours - origin.utcOffsetHours;
    final absDiff = diffHours.abs();

    // Standard clinical guideline: maximum 2 hours shift per day for standard meds,
    // 1 to 1.5 hours per day for narrow therapeutic index meds.
    final maxShiftPerDay = isNarrowTherapeutic ? 1.5 : 2.0;
    final transitionDays = math.max(1, (absDiff / maxShiftPerDay).ceil());

    final steps = <TravelDoseStep>[];
    final parts = originalTime.split(':');
    final origHour = int.tryParse(parts[0]) ?? 8;
    final origMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    // Day 0: Flight departure day
    steps.add(TravelDoseStep(
      dayNumber: 0,
      dateLabel: 'Departure Day (${origin.city})',
      scheduledTime: originalTime,
      shiftHoursFromOrigin: 0,
      clinicalInstruction: 'Take regular dose at $originalTime (${origin.region}) before boarding. Keep all medication in carry-on bag.',
      isFlightDay: true,
    ));

    // Intermediate transition days
    final direction = diffHours > 0 ? 1 : -1;
    final shiftStep = absDiff / transitionDays;

    for (int day = 1; day <= transitionDays; day++) {
      final currentShift = math.min(absDiff, shiftStep * day) * direction;
      var shiftedDecimalHours = origHour + (origMin / 60.0) + currentShift;

      // Wrap around 24h
      while (shiftedDecimalHours < 0) {
        shiftedDecimalHours += 24.0;
      }
      while (shiftedDecimalHours >= 24) {
        shiftedDecimalHours -= 24.0;
      }

      final h = shiftedDecimalHours.floor();
      final m = ((shiftedDecimalHours - h) * 60).round();
      final timeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      final isFinal = day == transitionDays;

      steps.add(TravelDoseStep(
        dayNumber: day,
        dateLabel: isFinal ? 'Destination Synchronized (${destination.city})' : 'Travel Day +$day (Phase Shift)',
        scheduledTime: timeStr,
        shiftHoursFromOrigin: currentShift,
        clinicalInstruction: isFinal
            ? 'Fully synchronized! Take standard dose at $timeStr local time in ${destination.city}.'
            : 'Intermediate circadian bridge: Take dose at $timeStr destination time (${currentShift >= 0 ? '+' : ''}${currentShift.toStringAsFixed(1)}h shift).',
        isFinalDestination: isFinal,
      ));
    }

    // Curated global travel clinical precautions
    final precautions = <String>[
      '✈️ Carry-On Only: Never put medications in checked luggage; cargo holds experience freezing temperatures and lost-luggage risks.',
      '🌡️ Cold-Chain Integrity: If carrying Insulin or Biologics, use an insulated cooling pouch with cold gel packs. Do not freeze.',
      '💧 Cabin Barometric Pressure: Ophthalmic eye dropper bottles expand in pressurized cabins. Open caps with tip pointing upwards to prevent spurting.',
      '📑 Medical Travel Certificate: Carry your doctor\'s prescription or MediMind Emergency Medical ID for international airport customs / TSA liquid exemptions.',
      '⏰ Flight Mode Alarms: Ensure device clock timezone auto-updates or relies on MediMind\'s internal GMT elapsed timer.',
    ];

    if (isNarrowTherapeutic) {
      precautions.insert(0, '⚠️ NARROW THERAPEUTIC INDEX: Do NOT abruptly shift clock by ${absDiff.toStringAsFixed(1)}h on arrival. Follow the gradual step schedule strictly to prevent toxicity or organ rejection.');
    }

    return CircadianTravelPlan(
      origin: origin,
      destination: destination,
      netTimeDifferenceHours: diffHours,
      recommendedTransitionDays: transitionDays,
      dosingSteps: steps,
      travelPrecautions: precautions,
      isNarrowTherapeutic: isNarrowTherapeutic,
    );
  }
}
