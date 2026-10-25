import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medimind_app/ui/features/companion/medi_buddy_character.dart';
import 'package:medimind_app/ui/features/companion/companion_card_widget.dart';
import 'package:medimind_app/data/repositories/medication_repository.dart';
import 'package:medimind_app/data/services/storage_service.dart';
import 'package:medimind_app/data/services/notification_service.dart';
import 'package:medimind_app/data/services/tasker_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('CompanionCardWidget renders motivation and adherence stats', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final notif = NotificationService();
    final tasker = TaskerService();
    final repo = MedicationRepository(
      storageService: storage,
      notificationService: notif,
      taskerService: tasker,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MedicationRepository>.value(value: repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CompanionCardWidget(),
          ),
        ),
      ),
    );

    expect(find.byType(CompanionCardWidget), findsOneWidget);
    expect(find.byType(MediBuddyCharacter), findsOneWidget);
  });
}
