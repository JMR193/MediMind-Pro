import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medimind_app/domain/models/medication.dart';
import 'package:medimind_app/domain/models/medication_log.dart';
import 'package:medimind_app/data/repositories/medication_repository.dart';
import 'package:medimind_app/data/services/storage_service.dart';
import 'package:medimind_app/data/services/notification_service.dart';
import 'package:medimind_app/data/services/tasker_service.dart';
import 'package:medimind_app/ui/features/alarm/medicine_alarm_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTablet = Medication(
    id: 'test_tab_1',
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

  testWidgets('MedicineAlarmDialog renders medication info and logs dose on take', (tester) async {
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
        child: MaterialApp(
          home: Scaffold(
            body: MedicineAlarmDialog(
              medication: testTablet,
              scheduledTime: '21:00',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Atorvastatin'), findsOneWidget);
    expect(find.textContaining('20 mg'), findsOneWidget);
    expect(find.text('Taken'), findsOneWidget);
    expect(find.text('Snooze 10 Min'), findsOneWidget);
    expect(find.text('Skip this dose'), findsOneWidget);

    await tester.tap(find.text('Taken'));
    await tester.pumpAndSettle();
    expect(repo.logs.any((l) => l.medicationId == 'test_tab_1' && l.status == LogStatus.taken), isTrue);
  });
}
