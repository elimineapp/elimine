import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/core/db/queries.dart';
import 'package:elimine/features/substance/substance_chart.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 9, 29, 14, 35);

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() => db.close());

  /// Creates a substance with one intake per `(day of September, amount)`
  /// entry and shows its chart for the current week (Monday 28 September to
  /// Sunday 4 October).
  Future<BarChartData> pumpChart(
    WidgetTester tester,
    List<(int day, double? amount)> intakes,
  ) async {
    final substance = (await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'orange',
        icon: 'coffee',
        doses: const [],
      ));
      final service = IntakeService(db, clock: () => now);
      for (final (day, amount) in intakes) {
        await service.log(
          substanceId: id,
          amount: amount,
          takenAt: DateTime(2026, 9, day, 9),
        );
      }
      return (await db.watchSubstance(id).first)!;
    }))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SubstanceChart(substance: substance, clock: () => now),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.widget<BarChart>(find.byType(BarChart)).data;
  }

  Future<void> finish(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('a mixed range sums doses and dots days without a dose', (
    tester,
  ) async {
    final data = await pumpChart(tester, [(28, 250), (28, null), (29, null)]);
    expect(find.text('Per day, mg'), findsOneWidget);

    expect(data.barGroups, hasLength(7));
    final [yesterday, today, ...] = data.barGroups;
    expect(yesterday.barRods.first.toY, 250);
    expect(yesterday.barRods, hasLength(2));
    expect(today.barRods.first.toY, 0);
    expect(today.barRods, hasLength(2));
    // Sunday has not come yet.
    expect(data.barGroups.last.barRods, hasLength(1));
    expect(data.barGroups.last.barRods.single.toY, 0);
    await finish(tester);
  });

  testWidgets('a range without any dose counts intakes', (tester) async {
    final data = await pumpChart(tester, [(26, null), (28, null), (28, null)]);
    expect(find.text('Intakes'), findsOneWidget);

    // Saturday the 26th belongs to the week before.
    final [yesterday, ...] = data.barGroups;
    expect(yesterday.barRods.single.toY, 2);
    expect(data.barGroups.every((g) => g.barRods.length == 1), isTrue);
    await finish(tester);
  });

  testWidgets('the year shows daily averages, this month over elapsed days', (
    tester,
  ) async {
    await pumpChart(tester, [(1, 290), (29, 0.5)]);
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    final data = tester.widget<BarChart>(find.byType(BarChart)).data;
    expect(find.text('Daily average, mg'), findsOneWidget);
    expect(data.barGroups, hasLength(12));
    // September: 290.5 mg over 29 days so far.
    expect(data.barGroups[8].barRods.first.toY, closeTo(290.5 / 29, 1e-9));
    expect(data.barGroups[11].barRods.first.toY, 0);
    await finish(tester);
  });

  testWidgets('previous stops at the first intake of this substance', (
    tester,
  ) async {
    // Another substance with an older intake does not move the limit.
    await tester.runAsync(() async {
      final other = await SubstanceService(db).create((
        name: 'Tea',
        unit: '',
        color: 'aqua',
        icon: 'leaf',
        doses: const [],
      ));
      await IntakeService(
        db,
        clock: () => now,
      ).log(substanceId: other, amount: null, takenAt: DateTime(2025, 1, 1, 9));
    });
    await pumpChart(tester, [(20, 100), (28, 100)]);
    bool enabled(String key) =>
        tester.widget<IconButton>(find.byKey(Key(key))).onPressed != null;

    expect(enabled('previousPeriod'), isTrue);
    expect(enabled('nextPeriod'), isFalse);
    await tester.tap(find.byKey(const Key('previousPeriod')));
    await tester.pumpAndSettle();
    expect(find.text('Sep 21 – Sep 27'), findsOneWidget);
    expect(enabled('previousPeriod'), isTrue);
    // Sunday the 20th, the first intake, ends the week before.
    await tester.tap(find.byKey(const Key('previousPeriod')));
    await tester.pumpAndSettle();
    expect(find.text('Sep 14 – Sep 20'), findsOneWidget);
    expect(enabled('previousPeriod'), isFalse);
    expect(enabled('nextPeriod'), isTrue);
    await finish(tester);
  });
}
