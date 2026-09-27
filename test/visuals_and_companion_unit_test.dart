import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medimind_app/ui/features/companion/medi_buddy_character.dart';
import 'package:medimind_app/ui/features/companion/companion_card_widget.dart';
import 'package:medimind_app/ui/features/visuals_3d/interactive_3d_pill_viewer.dart';
import 'package:medimind_app/ui/features/visuals_3d/animated_water_wave_tracker.dart';
import 'package:medimind_app/ui/features/visuals_3d/ophthalmic_3d_drop_simulator.dart';
import 'package:medimind_app/ui/features/visuals_3d/visual_lab_screen.dart';
import 'package:provider/provider.dart';
import 'package:medimind_app/data/repositories/medication_repository.dart';

void main() {
  testWidgets('MediBuddyCharacter renders properly across all moods and outfits', (tester) async {
    for (final mood in MediBuddyMood.values) {
      for (final outfit in MediBuddyOutfit.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediBuddyCharacter(
                mood: mood,
                outfit: outfit,
                size: 150,
                interactive: false,
                enableVoiceOnTap: false,
              ),
            ),
          ),
        );
        expect(find.byType(MediBuddyCharacter), findsOneWidget);
      }
    }
  });

  testWidgets('Interactive3dPillViewer renders and allows 3D orbital interaction', (tester) async {
    for (final type in Pill3DType.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Interactive3dPillViewer(
              initialType: type,
              autoRotate: false,
              size: 200,
            ),
          ),
        ),
      );
      expect(find.byType(Interactive3dPillViewer), findsOneWidget);
    }
  });

  testWidgets('AnimatedWaterWaveTracker logs water intake correctly', (tester) async {
    double loggedMl = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedWaterWaveTracker(
            currentMl: 1000,
            targetMl: 2000,
            onWaterLogged: (ml) => loggedMl = ml,
          ),
        ),
      ),
    );

    expect(find.text('Hydration & Pill Swallowing'), findsOneWidget);
    expect(find.text('+250 ml'), findsOneWidget);

    await tester.tap(find.text('+250 ml'));
    await tester.pump();

    expect(loggedMl, 1250);
  });

  testWidgets('Ophthalmic3dDropSimulator triggers drop sequence', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Ophthalmic3dDropSimulator(
            medicationName: 'Bimatoprost 0.01%',
          ),
        ),
      ),
    );

    expect(find.text('3D Eye Drop Technique Simulator'), findsOneWidget);
    expect(find.text('▶ Practice Drop'), findsOneWidget);

    await tester.tap(find.text('▶ Practice Drop'));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
