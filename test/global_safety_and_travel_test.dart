import 'package:flutter_test/flutter_test.dart';
import 'package:medimind_app/data/services/circadian_travel_service.dart';
import 'package:medimind_app/domain/models/medication.dart';

void main() {
  group('CircadianTravelService Tests', () {
    late CircadianTravelService service;

    setUp(() {
      service = CircadianTravelService();
    });

    Medication createTestMed({
      required String id,
      required String name,
      required String strength,
      required List<String> times,
      bool requiresEye = false,
    }) {
      return Medication(
        id: id,
        name: name,
        strength: strength,
        category: requiresEye ? MedCategory.eyeDrop : MedCategory.oral,
        dosageUnit: requiresEye ? DosageUnit.drops : DosageUnit.tablets,
        dosageAmount: 1.0,
        instruction: AdminInstruction.withMeal,
        scheduleTimes: times,
        totalInventoryCount: 30,
        refillThreshold: 5,
        colorHex: '#4A90E2',
        iconName: 'pill',
        requiresEyeDropProtocol: requiresEye,
      );
    }

    test('Identifies narrow therapeutic index and strict timing drugs', () {
      final warfarin = createTestMed(id: '1', name: 'Warfarin Sodium', strength: '5mg', times: ['18:00']);
      final tacrolimus = createTestMed(id: '2', name: 'Tacrolimus (Prograf)', strength: '1mg', times: ['08:00', '20:00']);
      final eyeDrop = createTestMed(id: '3', name: 'Latanoprost', strength: '0.005%', times: ['21:00'], requiresEye: true);
      final vitaminC = createTestMed(id: '4', name: 'Vitamin C', strength: '500mg', times: ['09:00']);

      expect(CircadianTravelService.isStrictTimingMedication(warfarin), isTrue);
      expect(CircadianTravelService.isStrictTimingMedication(tacrolimus), isTrue);
      expect(CircadianTravelService.isStrictTimingMedication(eyeDrop), isTrue);
      expect(CircadianTravelService.isStrictTimingMedication(vitaminC), isFalse);
    });

    test('Computes correct circadian phase shift from New York to Paris (+6 hours)', () {
      final ny = GlobalTimeZone.majorTimeZones.firstWhere((tz) => tz.city.contains('New York'));
      final paris = GlobalTimeZone.majorTimeZones.firstWhere((tz) => tz.city.contains('Paris'));

      final plan = service.calculateTravelPlan(
        origin: ny,
        destination: paris,
        originalTime: '08:00',
        departureDate: DateTime.now(),
        isNarrowTherapeutic: false,
      );

      expect(plan.netTimeDifferenceHours, equals(6.0));
      expect(plan.recommendedTransitionDays, equals(3)); // 6h / 2h per day = 3 days
      expect(plan.dosingSteps.length, equals(4)); // Day 0 + 3 transition days

      // Day 0 is flight departure
      expect(plan.dosingSteps[0].dayNumber, equals(0));
      expect(plan.dosingSteps[0].isFlightDay, isTrue);
      expect(plan.dosingSteps[0].scheduledTime, equals('08:00'));

      // Final day is synchronized
      expect(plan.dosingSteps.last.isFinalDestination, isTrue);
      expect(plan.travelPrecautions.isNotEmpty, isTrue);
    });

    test('Computes conservative transition days for narrow therapeutic drugs', () {
      final ny = GlobalTimeZone.majorTimeZones.firstWhere((tz) => tz.city.contains('New York'));
      final tokyo = GlobalTimeZone.majorTimeZones.firstWhere((tz) => tz.city.contains('Tokyo'));

      // New York (-5) to Tokyo (+9) = +14 hours
      final plan = service.calculateTravelPlan(
        origin: ny,
        destination: tokyo,
        originalTime: '08:00',
        departureDate: DateTime.now(),
        isNarrowTherapeutic: true,
      );

      expect(plan.netTimeDifferenceHours, equals(14.0));
      // 14 / 1.5 = 9.33 -> 10 days
      expect(plan.recommendedTransitionDays, equals(10));
      expect(plan.isNarrowTherapeutic, isTrue);
      expect(plan.travelPrecautions.first, contains('NARROW THERAPEUTIC INDEX'));
    });

    test('Global timezones cover worldwide regions', () {
      final timezones = GlobalTimeZone.majorTimeZones;
      expect(timezones.length, greaterThanOrEqualTo(10));

      final cities = timezones.map((tz) => tz.city).toList();
      expect(cities.any((c) => c.contains('London')), isTrue);
      expect(cities.any((c) => c.contains('New Delhi')), isTrue);
      expect(cities.any((c) => c.contains('Tokyo')), isTrue);
      expect(cities.any((c) => c.contains('Sydney')), isTrue);
      expect(cities.any((c) => c.contains('São Paulo')), isTrue);
    });
  });
}
