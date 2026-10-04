import 'analytics_queries.dart';

/// Scales shared by the analytics screen and the per-substance chart.
enum AnalyticsRange { twoWeeks, month, year, allYears }

enum BucketUnit { day, month, year }

/// One bar: a day, a month or a year. Dates are UTC midnights used as plain
/// calendar dates, so DST never shifts a bucket.
class Bucket {
  Bucket(this.start, this.end, this.unit);

  final DateTime start;

  /// Exclusive.
  final DateTime end;
  final BucketUnit unit;
  final Map<String, ({double total, int count})> bySubstance = {};

  int get count => bySubstance.values.fold(0, (sum, v) => sum + v.count);

  double totalFor(String substanceId) => bySubstance[substanceId]?.total ?? 0;

  /// Days of this bucket that have already happened, for daily averages of
  /// the current, unfinished month.
  int elapsedDays(DateTime today) {
    final last = today.isBefore(end) ? today.add(const Duration(days: 1)) : end;
    return last.difference(start).inDays.clamp(1, 366);
  }
}

/// All slots sharing the top count; sparse data ties often.
typedef Busiest = ({BucketUnit by, List<int> indexes, int count});

class PeriodStats {
  const PeriodStats({
    required this.total,
    required this.activeDays,
    required this.periodDays,
    required this.maxDay,
    required this.busiest,
    required this.shares,
  });

  final int total;
  final int activeDays;
  final int periodDays;

  /// The day with the most intakes (latest on a tie), or null without data.
  final ({DateTime day, int count})? maxDay;

  /// Weekdays (1 = Monday, as [DateTime.weekday]) for day ranges, months of
  /// the year (1..12) for longer ones.
  final Busiest? busiest;

  /// Share of intakes per substance, largest first.
  final List<({String substanceId, double share})> shares;
}

class Analytics {
  Analytics(this.range, this.buckets, this._days, this.today);

  /// Groups [rows] into continuous buckets for [range] ending on [today];
  /// empty periods stay as empty buckets. [visible] limits which substances
  /// count; null means all.
  factory Analytics.build(
    AnalyticsRange range,
    List<DailyTotal> rows, {
    required DateTime today,
    Set<String>? visible,
  }) {
    final day = _date(today);
    final parsed = [
      for (final r in rows)
        if (visible == null || visible.contains(r.substanceId))
          (day: DateTime.parse('${r.day}T00:00:00Z'), row: r),
    ];
    final earliest = parsed.isEmpty
        ? day
        : parsed.map((p) => p.day).reduce((a, b) => a.isBefore(b) ? a : b);
    final buckets = _skeleton(range, day, earliest);
    final start = buckets.first.start;
    final inRange = [
      for (final p in parsed)
        if (!p.day.isBefore(start) && !p.day.isAfter(day)) p,
    ];

    for (final p in inRange) {
      final bucket = buckets.lastWhere((b) => !p.day.isBefore(b.start));
      final prev = bucket.bySubstance[p.row.substanceId];
      bucket.bySubstance[p.row.substanceId] = (
        total: (prev?.total ?? 0) + p.row.total,
        count: (prev?.count ?? 0) + p.row.count,
      );
    }
    return Analytics(range, buckets, [
      for (final p in inRange) (day: p.day, row: p.row),
    ], day);
  }

  final AnalyticsRange range;
  final List<Bucket> buckets;
  final List<({DateTime day, DailyTotal row})> _days;
  final DateTime today;

  BucketUnit get unit => buckets.first.unit;

  /// Substances that have intakes in this period.
  Set<String> get substanceIds => {for (final d in _days) d.row.substanceId};

  PeriodStats stats() {
    final perDay = <DateTime, int>{};
    final perSubstance = <String, int>{};
    for (final (:day, :row) in _days) {
      perDay[day] = (perDay[day] ?? 0) + row.count;
      perSubstance[row.substanceId] =
          (perSubstance[row.substanceId] ?? 0) + row.count;
    }
    final total = perSubstance.values.fold(0, (a, b) => a + b);

    ({DateTime day, int count})? maxDay;
    for (final MapEntry(key: day, value: count) in perDay.entries) {
      if (maxDay == null ||
          count > maxDay.count ||
          (count == maxDay.count && day.isAfter(maxDay.day))) {
        maxDay = (day: day, count: count);
      }
    }

    final byWeekday = unit == BucketUnit.day;
    final slots = <int, int>{};
    for (final MapEntry(key: day, value: count) in perDay.entries) {
      final slot = byWeekday ? day.weekday : day.month;
      slots[slot] = (slots[slot] ?? 0) + count;
    }
    final top = slots.values.fold(0, (a, b) => a > b ? a : b);
    final Busiest? busiest = slots.isEmpty
        ? null
        : (
            by: byWeekday ? BucketUnit.day : BucketUnit.month,
            indexes: [
              for (final MapEntry(:key, :value) in slots.entries)
                if (value == top) key,
            ]..sort(),
            count: top,
          );

    final start = range == AnalyticsRange.allYears && _days.isNotEmpty
        ? _days.map((d) => d.day).reduce((a, b) => a.isBefore(b) ? a : b)
        : buckets.first.start;

    return PeriodStats(
      total: total,
      activeDays: perDay.length,
      periodDays: range == AnalyticsRange.allYears && _days.isEmpty
          ? 0
          : today.difference(start).inDays + 1,
      maxDay: maxDay,
      busiest: busiest,
      shares: [
        for (final MapEntry(:key, :value) in perSubstance.entries)
          (substanceId: key, share: value / total),
      ]..sort((a, b) => b.share.compareTo(a.share)),
    );
  }
}

DateTime _date(DateTime d) => DateTime.utc(d.year, d.month, d.day);

List<Bucket> _skeleton(
  AnalyticsRange range,
  DateTime today,
  DateTime earliest,
) {
  Bucket day(DateTime d) =>
      Bucket(d, d.add(const Duration(days: 1)), BucketUnit.day);
  Bucket month(int y, int m) =>
      Bucket(DateTime.utc(y, m), DateTime.utc(y, m + 1), BucketUnit.month);

  return switch (range) {
    AnalyticsRange.twoWeeks => [
      for (var i = 13; i >= 0; i--) day(today.subtract(Duration(days: i))),
    ],
    AnalyticsRange.month => [
      for (var i = 29; i >= 0; i--) day(today.subtract(Duration(days: i))),
    ],
    AnalyticsRange.year => [
      for (var i = 11; i >= 0; i--) month(today.year, today.month - i),
    ],
    AnalyticsRange.allYears => [
      for (var y = earliest.year; y <= today.year; y++)
        Bucket(DateTime.utc(y), DateTime.utc(y + 1), BucketUnit.year),
    ],
  };
}

/// Lower bound for the daily-totals query of [range]. Day precision keeps it
/// stable across rebuilds, so it can key a provider; a spare day covers
/// intakes logged in other time zones. Null means everything.
DateTime? rangeQuerySince(AnalyticsRange range, DateTime now) {
  final margin = const Duration(days: 2);
  return switch (range) {
    AnalyticsRange.twoWeeks => DateTime(now.year, now.month, now.day - 13),
    AnalyticsRange.month => DateTime(now.year, now.month, now.day - 29),
    AnalyticsRange.year => DateTime(now.year, now.month - 11),
    AnalyticsRange.allYears => null,
  }?.subtract(margin);
}
