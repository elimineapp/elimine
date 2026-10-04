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
  // Sunday 4 October 2026.
  final today = DateTime(2026, 10, 4, 21, 30);
  AnalyticsPeriod current(AnalyticsRange r, {int first = DateTime.monday}) =>
      AnalyticsPeriod.current(r, today, firstWeekday: first);

  group('periods', () {
    test('a week starts on Monday by default and on Sunday when chosen', () {
      final monday = current(AnalyticsRange.week);
      expect(monday.start, DateTime.utc(2026, 9, 28));
      expect(monday.end, DateTime.utc(2026, 10, 5));
      expect(monday.buckets.map((b) => b.start.day), [
        28, 29, 30, 1, 2, 3, 4, //
      ]);

      final sunday = current(AnalyticsRange.week, first: DateTime.sunday);
      expect(sunday.start, DateTime.utc(2026, 10, 4));
      expect(sunday.end, DateTime.utc(2026, 10, 11));
    });

    test('a week can span two years', () {
      final p = AnalyticsPeriod.current(
        AnalyticsRange.week,
        DateTime(2026, 1, 1),
      );
      expect(p.start, DateTime.utc(2025, 12, 29));
      expect(p.buckets.last.start, DateTime.utc(2026, 1, 4));
      expect(p.previous.start, DateTime.utc(2025, 12, 22));
    });

    test('a month has a slot for each of its days', () {
      expect(current(AnalyticsRange.month).buckets, hasLength(31));
      final leap = AnalyticsPeriod.of(
        AnalyticsRange.month,
        DateTime.utc(2028, 2),
      );
      expect(leap.buckets, hasLength(29));
      expect(
        AnalyticsPeriod.of(AnalyticsRange.month, DateTime.utc(2026, 2)).buckets,
        hasLength(28),
      );
    });

    test('a year runs from January to December', () {
      final p = current(AnalyticsRange.year);
      expect(p.buckets.map((b) => b.start.month), [
        for (var m = 1; m <= 12; m++) m,
      ]);
      expect(p.buckets.every((b) => b.start.year == 2026), isTrue);
    });

    test('stepping crosses year boundaries both ways', () {
      final jan = AnalyticsPeriod.of(AnalyticsRange.month, DateTime.utc(2026));
      expect(jan.previous.start, DateTime.utc(2025, 12));
      expect(jan.previous.next, jan);
      final y = current(AnalyticsRange.year);
      expect(y.previous.start, DateTime.utc(2025));
      expect(y.previous.end, DateTime.utc(2026));
    });

    test('stepping keeps the first weekday of every range', () {
      for (final r in [
        AnalyticsRange.week,
        AnalyticsRange.month,
        AnalyticsRange.year,
      ]) {
        final p = current(r, first: DateTime.sunday);
        expect(p.firstWeekday, DateTime.sunday, reason: '$r');
        expect(p.previous.firstWeekday, DateTime.sunday, reason: '$r');
        expect(p.previous.next, p, reason: '$r');
      }
    });

    test('next stops at the current period, previous at the first intake', () {
      final month = current(AnalyticsRange.month);
      expect(month.hasNext(today), isFalse);
      expect(month.previous.hasNext(today), isTrue);
      expect(month.hasPrevious(null), isFalse);
      expect(month.hasPrevious(DateTime(2026, 10, 1)), isFalse);
      expect(month.hasPrevious(DateTime(2026, 9, 30)), isTrue);
      expect(month.previous.hasPrevious(DateTime(2026, 9, 30)), isFalse);
    });

    test('elapsed days count the days that have begun', () {
      expect(current(AnalyticsRange.year).elapsedDays(today), 277);
      expect(current(AnalyticsRange.month).elapsedDays(today), 4);
      expect(current(AnalyticsRange.month).previous.elapsedDays(today), 30);
      expect(current(AnalyticsRange.week).elapsedDays(today), 7);
    });

    test('all years runs from the first intake year and does not step', () {
      final p = AnalyticsPeriod.current(
        AnalyticsRange.allYears,
        today,
        firstDay: DateTime(2024, 5, 1),
      );
      expect([for (final b in p.buckets) b.start.year], [2024, 2025, 2026]);
      expect(p.steps, isFalse);
      expect(p.hasPrevious(DateTime(2020)), isFalse);
      expect(p.querySince, isNull);
    });
  });

  test('buckets: future days stay empty, rows outside the period drop', () {
    final a = Analytics.build(current(AnalyticsRange.month), [
      row('2026-09-30', 'x'), // the month before
      row('2026-10-01', 'x', total: 10),
      row('2026-10-04', 'x', total: 5, count: 2),
      row('2026-10-04', 'y', total: 3),
    ], today: today);

    expect(a.buckets, hasLength(31));
    expect(a.buckets.first.totalFor('x'), 10);
    expect(a.buckets[3].count, 3);
    expect(a.buckets.skip(4).every((b) => b.count == 0), isTrue);
  });

  test('year buckets give daily averages over elapsed days', () {
    final a = Analytics.build(current(AnalyticsRange.year), [
      row('2026-01-10', 'x', total: 31),
      row('2026-10-02', 'x', total: 8),
    ], today: today);
    expect(
      a.buckets.first.totalFor('x') / a.buckets.first.elapsedDays(today),
      1,
    );
    // October is not over: 4 days so far.
    expect(a.buckets[9].elapsedDays(a.today), 4);
  });

  test('buckets keep intakes without a dose apart from dose sums', () {
    final a = Analytics.build(current(AnalyticsRange.week), [
      row('2026-10-04', 'x', total: 250, count: 3, dosed: 1),
    ], today: today);
    final last = a.buckets.last;
    expect(last.totalFor('x'), 250);
    expect(last.countFor('x'), 3);
    expect(last.undosedFor('x'), 2);
    expect(a.buckets.first.undosedFor('x'), 0);
  });

  test('stats: totals, active days, max day, busiest weekday, shares', () {
    final s = Analytics.build(current(AnalyticsRange.month).previous, [
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

  test('a week has no busiest weekday', () {
    final s = Analytics.build(current(AnalyticsRange.week), [
      row('2026-10-01', 'x', count: 2),
    ], today: today).stats();
    expect(s.busiest, isNull);
    expect((s.activeDays, s.periodDays), (1, 7));
  });

  test('stats respect the visible filter and busiest month on long ranges', () {
    final rows = [
      row('2026-03-01', 'x', count: 3),
      row('2026-05-01', 'y', count: 5),
    ];
    final year = current(AnalyticsRange.year);
    final all = Analytics.build(year, rows, today: today);
    final onlyX = Analytics.build(year, rows, today: today, visible: {'x'});

    expect(all.stats().busiest?.by, BucketUnit.month);
    expect(all.stats().busiest?.indexes, [5]);
    expect(onlyX.stats().total, 3);
    expect(onlyX.stats().busiest?.indexes, [3]);
    expect(all.substanceIds, {'x', 'y'});
  });

  test('ties list every busiest slot', () {
    final s = Analytics.build(current(AnalyticsRange.month).previous, [
      row('2026-09-24', 'x'), // Thursday
      row('2026-09-28', 'x'), // Monday
    ], today: today).stats();
    expect(s.busiest?.indexes, [DateTime.monday, DateTime.thursday]);
  });

  test('empty data gives empty buckets and no highlights', () {
    final s = Analytics.build(
      AnalyticsPeriod.current(AnalyticsRange.allYears, today),
      [],
      today: today,
    ).stats();
    expect((s.total, s.activeDays, s.periodDays), (0, 0, 0));
    expect(s.maxDay, isNull);
    expect(s.busiest, isNull);
  });

  group('week marks', () {
    List<int> marksOf(List<DailyTotal> rows, {int first = DateTime.monday}) =>
        weekMarks(rows, today, firstWeekday: first)['x'] ?? noWeekMarks;
    List<int> filled(List<int> marks) => [
      for (var i = 0; i < marks.length; i++)
        if (marks[i] > 0) i,
    ];

    test('cover 12 calendar weeks ending with the current one', () {
      expect(markedWeeksStart(today), DateTime.utc(2026, 7, 13));
      expect(
        markedWeeksStart(today, firstWeekday: DateTime.sunday),
        DateTime.utc(2026, 7, 19),
      );
    });

    test('an intake today fills the last mark', () {
      expect(filled(marksOf([row('2026-10-04', 'x')])), [11]);
    });

    test('an intake twelve days ago fills the previous week', () {
      // Tuesday 22 September, weeks from Monday.
      expect(filled(marksOf([row('2026-09-22', 'x')])), [10]);
    });

    test('weeks follow the chosen first day', () {
      // Saturday 3 October ends the week before when weeks start on Sunday.
      final rows = [row('2026-10-03', 'x')];
      expect(filled(marksOf(rows)), [11]);
      expect(filled(marksOf(rows, first: DateTime.sunday)), [10]);
    });

    test('an intake without a dose counts', () {
      final rows = [row('2026-10-01', 'x', total: 0, dosed: 0)];
      expect(filled(marksOf(rows)), [11]);
    });

    test('the oldest week is included, anything before it is not', () {
      final rows = [row('2026-07-12', 'x'), row('2026-07-13', 'x')];
      expect(filled(marksOf(rows)), [0]);
      expect(filled(marksOf([row('2026-07-12', 'x')])), isEmpty);
    });

    test('count the intakes of every day in a week', () {
      final marks = marksOf([
        row('2026-09-28', 'x', count: 2),
        row('2026-10-01', 'x', count: 1, dosed: 0),
        row('2026-10-04', 'x', count: 3),
        row('2026-09-22', 'x'),
      ]);
      expect(marks[11], 6);
      expect(marks[10], 1);
      expect(marks.take(10), everyElement(0));
    });

    test('a substance without intakes has no filled marks', () {
      final marks = weekMarks([row('2026-10-04', 'y')], today);
      expect(marks['x'] ?? noWeekMarks, hasLength(markedWeeks));
      expect(filled(marks['x'] ?? noWeekMarks), isEmpty);
      expect(filled(marks['y']!), [11]);
    });
  });
}
