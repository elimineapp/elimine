import 'package:elimine/features/analytics/analytics.dart';
import 'package:elimine/features/analytics/labels.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations ru;
  // Sunday 4 October 2026.
  final today = DateTime(2026, 10, 4);

  setUpAll(() async {
    await initializeDateFormatting();
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
  });

  AnalyticsPeriod current(AnalyticsRange r) =>
      AnalyticsPeriod.current(r, today);

  test('period titles', () {
    final week = current(AnalyticsRange.week);
    expect(en.periodTitle(week, today), 'Sep 28 – Oct 4');
    expect(ru.periodTitle(week, today), '28 сент. – 4 окт.');
    expect(
      en.periodTitle(current(AnalyticsRange.month), today),
      'October 2026',
    );
    // intl puts a non-breaking space of some kind before "г.".
    expect(
      ru
          .periodTitle(current(AnalyticsRange.month), today)
          .replaceAll(RegExp(r'\s'), ' '),
      'Октябрь 2026 г.',
    );
    expect(en.periodTitle(current(AnalyticsRange.year), today), '2026');
  });

  test('weeks outside this year carry their years', () {
    final turn = AnalyticsPeriod.current(
      AnalyticsRange.week,
      DateTime(2026, 1, 1),
    );
    expect(en.periodTitle(turn, today), 'Dec 29, 2025 – Jan 4, 2026');
    final old = AnalyticsPeriod.current(
      AnalyticsRange.week,
      DateTime(2025, 6, 4),
    );
    expect(en.periodTitle(old, today), 'Jun 2, 2025 – Jun 8, 2025');
  });

  test('axis labels', () {
    List<String> labels(AnalyticsRange r) {
      final b = current(r).buckets;
      return [
        for (final (i, x) in b.indexed) ru.bucketAxisLabel(x, i, b.length),
      ];
    }

    expect(labels(AnalyticsRange.week), [
      'пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс', //
    ]);
    final month = labels(AnalyticsRange.month);
    expect(
      [
        for (final (i, l) in month.indexed)
          if (l.isNotEmpty) (i + 1, l),
      ],
      [
        (1, '1'),
        (5, '5'),
        (10, '10'),
        (15, '15'),
        (20, '20'),
        (25, '25'),
        (30, '30'),
      ],
    );
    expect(labels(AnalyticsRange.year).where((l) => l.isNotEmpty), [
      'янв.', 'апр.', 'июль', 'окт.', //
    ]);
  });

  test('weekday titles are capitalised', () {
    expect(ru.weekdayTitle(DateTime.monday), 'Понедельник');
    expect(en.weekdayTitle(DateTime.sunday), 'Sunday');
  });
}
