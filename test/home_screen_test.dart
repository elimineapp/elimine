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

  testWidgets('the header has no settings action', (tester) async {
    await pumpHome(tester);

    expect(find.byKey(const Key('settingsAction')), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.settings_outlined),
      ),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox());
  });

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

  testWidgets('a tile marks the weeks the substance was taken in', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'orange',
        icon: 'coffee',
        doses: const [250],
      ));
      await IntakeService(db).log(substanceId: id, amount: 250);
    });

    await pumpHome(tester);

    final marks = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('weekStrip')),
            matching: find.byType(Container),
          ),
        )
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();
    expect(marks, hasLength(12));
    // Only this week, the last mark, is in the substance color.
    expect(marks.last, isNot(marks.first));
    expect(marks.take(11).toSet(), hasLength(1));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('marks get stronger with more intakes in a week', (tester) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'orange',
        icon: 'coffee',
        doses: const [250],
      ));
      final now = DateTime.now();
      // Four this week, two the week before, one the week before that.
      for (final (daysAgo, times) in [(0, 4), (7, 2), (14, 1)]) {
        for (var i = 0; i < times; i++) {
          await IntakeService(db).log(
            substanceId: id,
            amount: 250,
            // Just after midnight, so no entry slips into another day.
            takenAt: DateTime(now.year, now.month, now.day - daysAgo, 0, i),
          );
        }
      }
    });

    await pumpHome(tester);

    final alphas = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('weekStrip')),
            matching: find.byType(Container),
          ),
        )
        .map((c) => (c.decoration! as BoxDecoration).color!.a)
        .toList();
    expect(alphas[9], lessThan(alphas[10]));
    expect(alphas[10], lessThan(alphas[11]));
    expect(alphas[11], 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a long name wraps onto two lines', (tester) async {
    const name = 'Acetylsalicylic acid, extended release, 100 mg tablets';
    await tester.runAsync(
      () => SubstanceService(db).create((
        name: name,
        unit: 'mg',
        color: 'blue',
        icon: 'pill',
        doses: const [],
      )),
    );

    await pumpHome(tester);

    final text = tester.widget<Text>(find.text(name));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.text(name)).height, greaterThan(30));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('on first launch the only item is "New substance"', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('New substance'), findsOneWidget);
    expect(find.byKey(const Key('weekStrip')), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
