import 'package:elimine/features/analytics/analytics.dart';
import 'package:elimine/features/analytics/analytics_queries.dart';
import 'package:flutter_test/flutter_test.dart';

DailyTotal row(
  String day,
  String id, {
  double total = 1,
  int count = 1,
  int? dosed,
}) => (
  day: day,
  substanceId: id,
  total: total,
  count: count,
  dosed: dosed ?? count,
);

void main() {
  // A Tuesday.
  final today = DateTime(2026, 9, 29, 21, 30);

  test(
    'two weeks: 14 continuous days, empty ones kept, older rows dropped',
    () {
      final a = Analytics.build(AnalyticsRange.twoWeeks, [
        row('2026-09-15', 'x'), // one day before the window
        row('2026-09-16', 'x', total: 10),
        row('2026-09-29', 'x', total: 5, count: 2),
        row('2026-09-29', 'y', total: 3),
      ], today: today);

      expect(a.buckets, hasLength(14));
      expect(a.buckets.first.start, DateTime.utc(2026, 9, 16));
      expect(a.buckets.last.start, DateTime.utc(2026, 9, 29));
      expect(a.buckets.first.totalFor('x'), 10);
      expect(a.buckets.last.count, 3);
      expect(a.buckets.where((b) => b.count == 0), hasLength(12));
    },
  );

  test('year: 12 months across the new year, with daily averages', () {
    final a = Analytics.build(AnalyticsRange.year, [
      row('2025-10-01', 'x', total: 31),
      row('2026-09-10', 'x', total: 29),
    ], today: today);

    expect(a.buckets.first.start, DateTime.utc(2025, 10));
    expect(a.buckets.last.start, DateTime.utc(2026, 9));
    expect(
      a.buckets.first.totalFor('x') / a.buckets.first.elapsedDays(a.today),
      1,
    );
    // September is not over: 29 days so far.
    expect(a.buckets.last.elapsedDays(a.today), 29);
  });

  test('buckets keep intakes without a dose apart from dose sums', () {
    final a = Analytics.build(AnalyticsRange.twoWeeks, [
      row('2026-09-29', 'x', total: 250, count: 3, dosed: 1),
    ], today: today);
    final last = a.buckets.last;
    expect(last.totalFor('x'), 250);
    expect(last.countFor('x'), 3);
    expect(last.undosedFor('x'), 2);
    expect(a.buckets.first.undosedFor('x'), 0);
  });

  test('all years starts at the first intake year', () {
    final a = Analytics.build(AnalyticsRange.allYears, [
      row('2024-05-01', 'x'),
      row('2026-01-01', 'x'),
    ], today: today);
    expect([for (final b in a.buckets) b.start.year], [2024, 2025, 2026]);
  });

  test('stats: totals, active days, max day, busiest weekday, shares', () {
    final s = Analytics.build(AnalyticsRange.month, [
      row('2026-09-21', 'x', count: 2), // Monday
      row('2026-09-28', 'x', count: 2), // Monday
      row('2026-09-28', 'y', count: 2),
      row('2026-09-29', 'y', count: 2), // Tuesday
    ], today: today).stats();

    expect(s.total, 8);
    expect((s.activeDays, s.periodDays), (3, 30));
    expect(s.maxDay, (day: DateTime.utc(2026, 9, 28), count: 4));
    expect(s.busiest?.by, BucketUnit.day);
    expect(s.busiest?.indexes, [DateTime.monday]);
    expect(s.busiest?.count, 6);
    expect(s.shares.map((e) => (e.substanceId, e.share)), [
      ('x', 0.5),
      ('y', 0.5),
    ]);
  });

  test('stats respect the visible filter and busiest month on long ranges', () {
    final rows = [
      row('2026-03-01', 'x', count: 3),
      row('2026-05-01', 'y', count: 5),
    ];
    final all = Analytics.build(AnalyticsRange.year, rows, today: today);
    final onlyX = Analytics.build(
      AnalyticsRange.year,
      rows,
      today: today,
      visible: {'x'},
    );

    expect(all.stats().busiest?.by, BucketUnit.month);
    expect(all.stats().busiest?.indexes, [5]);
    expect(onlyX.stats().total, 3);
    expect(onlyX.stats().busiest?.indexes, [3]);
    expect(all.substanceIds, {'x', 'y'});
  });

  test('ties list every busiest slot', () {
    final s = Analytics.build(AnalyticsRange.month, [
      row('2026-09-24', 'x'), // Thursday
      row('2026-09-28', 'x'), // Monday
    ], today: today).stats();
    expect(s.busiest?.indexes, [DateTime.monday, DateTime.thursday]);
  });

  test('empty data gives empty buckets and no highlights', () {
    final s = Analytics.build(
      AnalyticsRange.allYears,
      [],
      today: today,
    ).stats();
    expect((s.total, s.activeDays, s.periodDays), (0, 0, 0));
    expect(s.maxDay, isNull);
    expect(s.busiest, isNull);
  });
}
