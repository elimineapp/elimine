import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/core/db/queries.dart';
import 'package:elimine/features/substance/substance_screen.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late String id;
  final now = DateTime(2026, 9, 29, 14, 35);

  setUp(() async {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    id = await SubstanceService(db).create((
      name: 'Coffee',
      unit: 'mg',
      color: 'amber',
      icon: 'coffee',
      doses: [100, 200],
    ));
  });

  tearDown(() => db.close());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SubstanceScreen(substanceId: id, clock: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool isSelected(WidgetTester tester, String label) => tester
      .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
      .selected;

  Future<List<Intake>> logged() => db.watchIntakesFor(id).first;

  // Unmount first so stream subscriptions are gone before the fake clock
  // stops; the database itself is closed outside fake time in tearDown.
  Future<void> finish(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('first dose is preselected before any intake', (tester) async {
    await pumpScreen(tester);
    expect(isSelected(tester, '100 mg'), isTrue);
    expect(find.text('Now (today, 14:35)'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('last dose is preselected, shown even if not frequent', (
    tester,
  ) async {
    await tester.runAsync(
      () => IntakeService(db)
          .log(substanceId: id, amount: 150, takenAt: DateTime(2026, 9, 20)),
    );
    await pumpScreen(tester);
    expect(isSelected(tester, '150 mg'), isTrue);
    expect(isSelected(tester, '100 mg'), isFalse);
    await finish(tester);
  });

  testWidgets('Yesterday + dose + Log records it and resets to now', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Yesterday'));
    await tester.tap(find.text('200 mg'));
    await tester.pumpAndSettle();
    expect(find.text('Yesterday, 14:35'), findsOneWidget);

    await tester.tap(find.byKey(const Key('logButton')));
    await tester.pumpAndSettle();

    final intake = (await tester.runAsync(logged))!.single;
    expect(intake.amount, 200);
    expect(intake.takenAt, DateTime(2026, 9, 28, 14, 35));
    expect(find.text('Logged 200 mg'), findsOneWidget);
    expect(find.text('Now (today, 14:35)'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('time row picks a date, then a time', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('timeRow')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Sep 15, 14:35'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('custom dose accepts a decimal comma', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '12,5');
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(isSelected(tester, '12.5 mg'), isTrue);
    await finish(tester);
  });
}
