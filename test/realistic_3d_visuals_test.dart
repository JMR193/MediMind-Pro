import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/domain/models/medication.dart';
import 'package:medication_reminder/ui/features/companion/medi_buddy_character.dart';
import 'package:medication_reminder/ui/features/visuals_3d/interactive_3d_pill_viewer.dart';
import 'package:medication_reminder/ui/features/visuals_3d/realistic_3d_medicine_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTablet = Medication(
    id: 'test_tab',
    name: 'Atorvastatin',
    strength: '20 mg',
    category: MedCategory.oral,
    dosageUnit: DosageUnit.tablets,
    dosageAmount: 1,
    instruction: AdminInstruction.atBedtime,
    scheduleTimes: ['21:00'],
    totalInventoryCount: 30,
    refillThreshold: 7,
    colorHex: '#0284C7',
    iconName: 'tablet',
  );

  final testEyeDrop = Medication(
    id: 'test_drop',
    name: 'Timolol Maleate',
    strength: '0.5%',
    category: MedCategory.eyeDrop,
    dosageUnit: DosageUnit.drops,
    dosageAmount: 1,
    instruction: AdminInstruction.beforeMeal,
    scheduleTimes: ['08:00'],
    totalInventoryCount: 3,
    refillThreshold: 5,
    colorHex: '#7C3AED',
    iconName: 'eye_drop',
  );

  testWidgets('Realistic3dMedicineCard renders tablet with 3D canvas and details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Realistic3dMedicineCard(medication: testTablet),
        ),
      ),
    );

    expect(find.text('Atorvastatin'), findsOneWidget);
    expect(find.text('1 tablets • 20 mg'), findsOneWidget);
    expect(find.text('21:00'), findsOneWidget);
    expect(find.text('30 left'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('Realistic3dMedicineCard renders eye drop with badge and low inventory warning', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Realistic3dMedicineCard(medication: testEyeDrop),
        ),
      ),
    );

    expect(find.text('Timolol Maleate'), findsOneWidget);
    expect(find.text('EYE DROP'), findsOneWidget);
    expect(find.text('3 left'), findsOneWidget);
  });

  testWidgets('Interactive3dPillViewer renders 3D viewport without errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Interactive3dPillViewer(
            initialType: Pill3DType.capsule,
            size: 200,
          ),
        ),
      ),
    );

    expect(find.byType(Interactive3dPillViewer), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('MediBuddyCharacter renders successfully with custom speech', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediBuddyCharacter(
            mood: MediBuddyMood.celebrating,
            outfit: MediBuddyOutfit.champion,
            size: 100,
            customSpeechText: 'Great job taking your meds!',
          ),
        ),
      ),
    );

    expect(find.byType(MediBuddyCharacter), findsOneWidget);
    expect(find.text('Great job taking your meds!'), findsOneWidget);
  });
}
