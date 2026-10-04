import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/core/db/queries.dart';
import 'package:elimine/features/substance/substance_screen.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:elimine/widgets/intake_tile.dart';
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

  /// Pumps the substance screen on its own and, unless [expanded] is false,
  /// pulls it up to the full screen with the chart and history.
  Future<void> pumpScreen(
    WidgetTester tester, {
    String? substanceId,
    bool expanded = true,
  }) async {
    // A phone-sized screen, so the collapsed sheet fits its logging block.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SubstanceScreen(
            substanceId: substanceId ?? id,
            clock: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (expanded) {
      await tester.tap(find.byKey(const Key('chartAndHistory')));
      await tester.pumpAndSettle();
    }
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

  testWidgets('a last intake without a dose preselects nothing', (
    tester,
  ) async {
    await tester.runAsync(
      () => IntakeService(db)
          .log(substanceId: id, amount: null, takenAt: DateTime(2026, 9, 20)),
    );
    await pumpScreen(tester);
    expect(isSelected(tester, '100 mg'), isFalse);
    expect(isSelected(tester, '200 mg'), isFalse);
    await tester.scrollUntilVisible(
      find.byType(IntakeTile),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<ListTile>(
            find.descendant(
              of: find.byType(IntakeTile),
              matching: find.byType(ListTile),
            ),
          )
          .trailing,
      isNull,
    );
    await finish(tester);
  });

  testWidgets('tapping the selected dose clears it and logs no dose', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text('100 mg'));
    await tester.pumpAndSettle();
    expect(isSelected(tester, '100 mg'), isFalse);

    await tester.tap(find.byKey(const Key('logButton')));
    await tester.pumpAndSettle();

    final intake = (await tester.runAsync(logged))!.single;
    expect(intake.amount, isNull);
    expect(find.text('Logged'), findsOneWidget);
    await finish(tester);
  });

  Future<void> scrollToHistory(WidgetTester tester) =>
      tester.scrollUntilVisible(
        find.byType(IntakeTile),
        300,
        scrollable: find.byType(Scrollable).first,
      );

  testWidgets('swiping an entry away deletes it; Undo restores it', (
    tester,
  ) async {
    await tester.runAsync(
      () => IntakeService(db)
          .log(substanceId: id, amount: 100, takenAt: DateTime(2026, 9, 20)),
    );
    await pumpScreen(tester);
    await scrollToHistory(tester);

    await tester.drag(find.byType(IntakeTile), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Entry deleted'), findsOneWidget);
    expect(await tester.runAsync(logged), isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect((await tester.runAsync(logged))!.single.amount, 100);
    await finish(tester);
  });

  testWidgets('a substance without doses or unit logs without a dose', (
    tester,
  ) async {
    final bare = (await tester.runAsync(
      () => SubstanceService(db).create((
        name: 'Tea',
        unit: '',
        color: 'green',
        icon: 'coffee',
        doses: const [],
      )),
    ))!;
    await pumpScreen(tester, substanceId: bare);
    expect(find.text('Tea'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('doses')),
        matching: find.byType(ChoiceChip),
      ),
      findsNothing,
    );
    expect(find.widgetWithText(ActionChip, 'Custom'), findsOneWidget);

    await tester.tap(find.byKey(const Key('logButton')));
    await tester.pumpAndSettle();

    final intake = (await tester.runAsync(
      () => db.watchIntakesFor(bare).first,
    ))!.single;
    expect(intake.amount, isNull);
    expect(find.text('Logged'), findsOneWidget);
    await finish(tester);
  });

  group('edit sheet', () {
    Finder inSheet(Finder finder) =>
        find.descendant(of: find.byType(BottomSheet), matching: finder);

    bool isSelectedInSheet(WidgetTester tester, String label) => tester
        .widget<ChoiceChip>(inSheet(find.widgetWithText(ChoiceChip, label)))
        .selected;

    Future<void> logAt(WidgetTester tester, DateTime at, double? amount) =>
        tester.runAsync(
          () =>
              IntakeService(db)
                  .log(substanceId: id, amount: amount, takenAt: at),
        );

    Future<void> openSheet(WidgetTester tester) async {
      await pumpScreen(tester);
      await scrollToHistory(tester);
      await tester.tap(find.byType(IntakeTile));
      await tester.pumpAndSettle();
      expect(find.text('Edit entry'), findsOneWidget);
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('saveIntake')));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the intake time and dose', (tester) async {
      await logAt(tester, DateTime(2026, 9, 28, 9, 10), 100);
      await openSheet(tester);

      expect(inSheet(find.text('Yesterday, 09:10')), findsOneWidget);
      expect(isSelectedInSheet(tester, 'Yesterday'), isTrue);
      expect(isSelectedInSheet(tester, 'Now'), isFalse);
      expect(isSelectedInSheet(tester, '100 mg'), isTrue);
      expect(isSelectedInSheet(tester, '200 mg'), isFalse);
      await finish(tester);
    });

    testWidgets('adding a forgotten dose; Undo puts it back', (tester) async {
      await logAt(tester, DateTime(2026, 9, 20, 8), null);
      await openSheet(tester);
      expect(isSelectedInSheet(tester, '100 mg'), isFalse);
      expect(isSelectedInSheet(tester, '200 mg'), isFalse);

      await tester.tap(inSheet(find.text('200 mg')));
      await tester.pump();
      await save(tester);

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Entry updated'), findsOneWidget);
      var intake = (await tester.runAsync(logged))!.single;
      expect(intake.amount, 200);
      expect(intake.takenAt, DateTime(2026, 9, 20, 8));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      intake = (await tester.runAsync(logged))!.single;
      expect(intake.amount, isNull);
      await finish(tester);
    });

    testWidgets('clearing the dose saves an intake without one', (
      tester,
    ) async {
      await logAt(tester, DateTime(2026, 9, 20, 8), 100);
      await openSheet(tester);
      await tester.tap(inSheet(find.text('100 mg')));
      await tester.pump();
      await save(tester);

      expect((await tester.runAsync(logged))!.single.amount, isNull);
      await finish(tester);
    });

    testWidgets('"Yesterday" keeps the time of day', (tester) async {
      await logAt(tester, DateTime(2026, 9, 29, 10), 100);
      await openSheet(tester);
      await tester.tap(inSheet(find.text('Yesterday')));
      await tester.pump();
      expect(inSheet(find.text('Yesterday, 10:00')), findsOneWidget);
      await save(tester);

      expect(
        (await tester.runAsync(logged))!.single.takenAt,
        DateTime(2026, 9, 28, 10),
      );
      await finish(tester);
    });

    testWidgets('saving unchanged closes without a snackbar', (tester) async {
      await logAt(tester, DateTime(2026, 9, 20, 8), 100);
      await openSheet(tester);
      await save(tester);

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Entry updated'), findsNothing);
      await finish(tester);
    });

    testWidgets('closing without "Save" keeps the intake', (tester) async {
      await logAt(tester, DateTime(2026, 9, 20, 8), 100);
      await openSheet(tester);
      await tester.tap(inSheet(find.text('200 mg')));
      await tester.pump();
      // The barrier above the sheet.
      await tester.tapAt(const Offset(400, 20));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect((await tester.runAsync(logged))!.single.amount, 100);
      await finish(tester);
    });

    testWidgets('"Delete" closes the sheet and offers Undo', (tester) async {
      await logAt(tester, DateTime(2026, 9, 20, 8), 100);
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('deleteIntake')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Entry deleted'), findsOneWidget);
      expect(await tester.runAsync(logged), isEmpty);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect((await tester.runAsync(logged))!.single.amount, 100);
      await finish(tester);
    });
  });
}
