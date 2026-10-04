import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/features/analytics/analytics_screen.dart';
import 'package:elimine/features/analytics/bar_chart.dart';
import 'package:elimine/features/analytics/period_bar.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 9, 29, 20);

  setUp(() async {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    final substances = SubstanceService(db);
    final intakes = IntakeService(db, clock: () => now);
    Future<String> create(String name, String color) => substances.create((
      name: name,
      unit: 'mg',
      color: color,
      icon: 'pill',
      doses: [],
    ));
    final coffee = await create('Coffee', 'blue');
    final tea = await create('Tea', 'orange');
    // Two on Monday the 28th, one on Tuesday the 29th, one long ago.
    for (final (id, at) in [
      (coffee, DateTime(2026, 9, 28, 9)),
      (tea, DateTime(2026, 9, 28, 18)),
      (coffee, DateTime(2026, 9, 29, 9)),
      (coffee, DateTime(2025, 1, 5, 9)),
    ]) {
      await intakes.log(substanceId: id, amount: 100, takenAt: at);
    }
  });
  tearDown(() => db.close());

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AnalyticsScreen(clock: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder metric(String label, String value) => find.ancestor(
    of: find.text(value),
    matching: find.widgetWithText(Row, label),
  );

  testWidgets('month: counts, active days, max day, busiest weekday, share', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(metric('Total intakes', '3'), findsOneWidget);
    expect(metric('Days with intakes', '2 of 29'), findsOneWidget);
    expect(metric('Most in a day', '2 (Sep 28)'), findsOneWidget);
    expect(metric('Busiest weekday', 'Monday'), findsOneWidget);
    expect(metric('Coffee', '67%'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hiding a substance recomputes metrics', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Tea'));
    await tester.pumpAndSettle();
    expect(metric('Total intakes', '2'), findsOneWidget);
    expect(find.text('Share of intakes'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a long value wraps and leaves the label readable', (
    tester,
  ) async {
    // Two intakes on every day from Wednesday to Sunday tie with Monday.
    await tester.runAsync(() async {
      final coffee = (await db.select(db.substances).get())
          .firstWhere((s) => s.name == 'Coffee')
          .id;
      final intakes = IntakeService(db, clock: () => now);
      for (var day = 23; day <= 27; day++) {
        for (final hour in [9, 18]) {
          await intakes.log(
            substanceId: coffee,
            amount: 100,
            takenAt: DateTime(2026, 9, day, hour),
          );
        }
      }
    });
    await pumpScreen(tester);
    final value = find.text(
      'Monday, Wednesday, Thursday, Friday, Saturday, Sunday',
    );
    expect(value, findsOneWidget);
    final label = tester.getSize(find.text('Busiest weekday'));
    expect(label.width, greaterThan(100));
    expect(label.height, lessThan(3 * 24));
    expect(tester.getSize(value).width, lessThanOrEqualTo(360 * 0.6));
    await tester.pumpWidget(const SizedBox());
  });

  Finder label(String text) => find.descendant(
    of: find.byKey(const Key('periodLabel')),
    matching: find.text(text),
  );
  int barCount(WidgetTester tester) =>
      tester.widget<ElimineBarChart>(find.byType(ElimineBarChart)).bars.length;
  bool enabled(WidgetTester tester, String key) =>
      tester.widget<IconButton>(find.byKey(Key(key))).onPressed != null;

  testWidgets('the current month has a slot per day and cannot go forward', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(label('September 2026'), findsOneWidget);
    expect(barCount(tester), 30);
    expect(enabled(tester, 'nextPeriod'), isFalse);
    expect(enabled(tester, 'previousPeriod'), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('previous shows the month before; the label returns to now', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('previousPeriod')));
    await tester.pumpAndSettle();
    expect(label('August 2026'), findsOneWidget);
    expect(barCount(tester), 31);
    expect(find.text('Nothing logged in this period'), findsOneWidget);
    expect(enabled(tester, 'nextPeriod'), isTrue);

    await tester.tap(find.byKey(const Key('periodLabel')));
    await tester.pumpAndSettle();
    expect(label('September 2026'), findsOneWidget);
    expect(metric('Total intakes', '3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('previous stops at the period of the first intake', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(label('2026'), findsOneWidget);
    expect(barCount(tester), 12);
    await tester.tap(find.byKey(const Key('previousPeriod')));
    await tester.pumpAndSettle();
    expect(label('2025'), findsOneWidget);
    expect(metric('Total intakes', '1'), findsOneWidget);
    expect(metric('Days with intakes', '1 of 365'), findsOneWidget);
    expect(enabled(tester, 'previousPeriod'), isFalse);

    // Switching the range shows its current period.
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(label('September 2026'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('months step with a Sunday-first week too', (tester) async {
    await tester.runAsync(
      () => SettingsService(db).setWeekStart(DateTime.sunday),
    );
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('previousPeriod')));
    await tester.pumpAndSettle();
    expect(label('August 2026'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a fling on the chart steps through periods', (tester) async {
    await pumpScreen(tester);
    final chart = find.byType(ElimineBarChart);
    await tester.fling(chart, const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(label('August 2026'), findsOneWidget);
    await tester.fling(chart, const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(label('September 2026'), findsOneWidget);
    // Nothing after the current month.
    await tester.fling(chart, const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(label('September 2026'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('weeks start on Monday, or on Sunday when chosen', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(label('Sep 28 – Oct 4'), findsOneWidget);
    expect(barCount(tester), 7);
    expect(find.text('Busiest weekday'), findsNothing);
    expect(metric('Days with intakes', '2 of 2'), findsOneWidget);

    await tester.runAsync(
      () => SettingsService(db).setWeekStart(DateTime.sunday),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(label('Sep 27 – Oct 3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('taps still reach a page; a fling turns it', (tester) async {
    var taps = 0;
    var back = 0;
    final controller = PageController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodPages(
            controller: controller,
            count: 3,
            height: 200,
            onPageChanged: (b) => back = b,
            itemBuilder: (context, b) => GestureDetector(
              key: Key('page$b'),
              onTap: () => taps++,
              child: const ColoredBox(color: Color(0xFF000000)),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('page0')));
    // Older periods are to the left: dragging right shows them.
    await tester.fling(
      find.byKey(const Key('page0')),
      const Offset(300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect((taps, back), (1, 1));
  });

  testWidgets('all years includes old intakes', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(metric('Total intakes', '4'), findsOneWidget);
    expect(metric('Busiest month', 'September'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
