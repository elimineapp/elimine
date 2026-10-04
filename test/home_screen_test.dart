import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/features/home/home_screen.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:elimine/widgets/intake_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a tile shows the name without the unit', (tester) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'amber',
        icon: 'coffee',
        doses: const [250],
      ));
      await IntakeService(db).log(substanceId: id, amount: 250);
    });

    await pumpHome(tester);

    expect(find.text('Coffee'), findsWidgets);
    expect(find.text('Coffee, mg'), findsNothing);
    expect(find.text('250 mg · today'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a last intake without a dose shows only when it happened', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Tea',
        unit: '',
        color: 'green',
        icon: 'coffee',
        doses: const [],
      ));
      await IntakeService(db).log(
        substanceId: id,
        amount: null,
        takenAt: DateTime.now().subtract(const Duration(days: 1)),
      );
    });

    await pumpHome(tester);

    // The tile: name without a unit, then only the relative day.
    expect(find.text('Tea'), findsWidgets);
    expect(find.text('yesterday'), findsOneWidget);
    // The "Recent" entry: no dose, and nothing in its place.
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

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping a "Recent" entry opens its edit sheet', (tester) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'amber',
        icon: 'coffee',
        doses: const [250],
      ));
      await IntakeService(db).log(substanceId: id, amount: 250);
    });

    await pumpHome(tester);
    await tester.ensureVisible(find.byType(IntakeTile));
    await tester.tap(find.byType(IntakeTile));
    await tester.pumpAndSettle();

    expect(find.text('Edit entry'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Coffee'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
  });
}
