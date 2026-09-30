import 'package:flutter_test/flutter_test.dart';
import 'package:medimind_app/data/services/ai_omniroute_service.dart';
import 'package:medimind_app/domain/models/medication.dart';

void main() {
  group('AiOmniRouteService Hybrid Engine Tests', () {
    late AiOmniRouteService omniRouter;
    late List<Medication> testCabinet;

    setUp(() {
      omniRouter = AiOmniRouteService();
      testCabinet = [
        Medication(
          id: '1',
          name: 'Atorvastatin',
          strength: '20mg',
          category: MedCategory.oral,
          dosageUnit: DosageUnit.tablets,
          dosageAmount: 1.0,
          instruction: AdminInstruction.atBedtime,
          scheduleTimes: ['21:30'],
          totalInventoryCount: 30,
          refillThreshold: 5,
          colorHex: '#4A90E2',
          iconName: 'pill',
        ),
        Medication(
          id: '2',
          name: 'Latanoprost',
          strength: '0.005%',
          category: MedCategory.eyeDrop,
          dosageUnit: DosageUnit.drops,
          dosageAmount: 1.0,
          instruction: AdminInstruction.atBedtime,
          scheduleTimes: ['21:00'],
          totalInventoryCount: 1,
          refillThreshold: 1,
          colorHex: '#10B981',
          iconName: 'drop',
          requiresEyeDropProtocol: true,
        ),
      ];
    });

    test('Routes Pharmacokinetic curve simulation to Symbolic Bateman ODE engine', () async {
      final res = await omniRouter.routeQuery(
        query: 'What is my steady-state blood plasma curve and accumulation for Atorvastatin?',
        activeCabinet: testCabinet,
      );

      expect(res.telemetry.routeUsed, equals(AiOmniRouteTier.symbolicClinicalMath));
      expect(res.telemetry.domain, equals(AiWorkloadDomain.pharmacokineticSimulation));
      expect(res.telemetry.isDeterministicSafetyVerified, isTrue);
      expect(res.structuredData.containsKey('cMax'), isTrue);
      expect(res.structuredData.containsKey('cMin'), isTrue);
      expect(res.responseText, contains('Pharmacokinetic Bateman 1-Compartment Simulation'));
    });

    test('Routes Food & Nutrient interaction check to Deterministic Clinical Knowledge Graph', () async {
      final res = await omniRouter.routeQuery(
        query: 'Can I eat grapefruit with my morning cholesterol pills?',
        activeCabinet: testCabinet,
      );

      expect(res.telemetry.routeUsed, equals(AiOmniRouteTier.symbolicClinicalMath));
      expect(res.telemetry.domain, equals(AiWorkloadDomain.drugInteractionSafety));
      expect(res.telemetry.isDeterministicSafetyVerified, isTrue);
      expect(res.responseText, contains('grapefruit'));
    });

    test('Routes Pill Identification to LiteRT Edge Vision Pipeline', () async {
      final res = await omniRouter.routeQuery(
        query: 'Use camera to identify white round pill with score mark',
        activeCabinet: testCabinet,
      );

      expect(res.telemetry.routeUsed, equals(AiOmniRouteTier.edgeLiteRtVision));
      expect(res.telemetry.domain, equals(AiWorkloadDomain.visualPillIdentification));
      expect(res.structuredData.containsKey('confidence'), isTrue);
      expect(res.telemetry.modelEngine, contains('LiteRT'));
    });

    test('Routes Chronotherapy to Circadian Biological Clock Engine', () async {
      final res = await omniRouter.routeQuery(
        query: 'What is the optimal circadian schedule and time to take my meds?',
        activeCabinet: testCabinet,
      );

      expect(res.telemetry.routeUsed, equals(AiOmniRouteTier.symbolicClinicalMath));
      expect(res.telemetry.domain, equals(AiWorkloadDomain.circadianChronobiology));
      expect(res.structuredData.containsKey('evaluationsCount'), isTrue);
    });

    test('Maintains live inference telemetry history with latency tracking', () async {
      await omniRouter.routeQuery(query: 'plasma curve', activeCabinet: testCabinet);
      await omniRouter.routeQuery(query: 'identify pill', activeCabinet: testCabinet);

      expect(omniRouter.telemetryHistory.length, equals(2));
      expect(omniRouter.telemetryHistory.first.latencyMs, greaterThanOrEqualTo(1));
    });
  });
}
