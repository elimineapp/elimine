import 'analytics_queries.dart';

/// Scales shared by the analytics screen and the per-substance chart.
enum AnalyticsRange { week, month, year, allYears }

enum BucketUnit { day, month, year }

/// One bar: a day, a month or a year. Dates are UTC midnights used as plain
/// calendar dates, so DST never shifts a bucket.
class Bucket {
  Bucket(this.start, this.end, this.unit);

  final DateTime start;

  /// Exclusive.
  final DateTime end;
  final BucketUnit unit;
  final Map<String, ({double total, int count, int dosed})> bySubstance = {};

  int get count => bySubstance.values.fold(0, (sum, v) => sum + v.count);

  double totalFor(String substanceId) => bySubstance[substanceId]?.total ?? 0;

  int countFor(String substanceId) => bySubstance[substanceId]?.count ?? 0;

  /// Intakes of [substanceId] in this bucket that have no dose.
  int undosedFor(String substanceId) {
    final v = bySubstance[substanceId];
    return v == null ? 0 : v.count - v.dosed;
  }

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

  /// Weekdays (1 = Monday, as [DateTime.weekday]) for a month, months of
  /// the year (1..12) for longer ranges, null for a week or without data.
  final Busiest? busiest;

  /// Share of intakes per substance, largest first.
  final List<({String substanceId, double share})> shares;
}

/// One displayed period: a calendar week, month or year, or every year from
/// the first intake. [start] and [end] (exclusive) are UTC midnights used as
/// plain calendar dates.
class AnalyticsPeriod {
  const AnalyticsPeriod._(this.range, this.start, this.end, this.firstWeekday);

  /// The period of [range] that contains [today]. Weeks start on
  /// [firstWeekday] ([DateTime.monday] or [DateTime.sunday]); "All"
  /// starts in the year of [firstDay], or this year without intakes.
  factory AnalyticsPeriod.current(
    AnalyticsRange range,
    DateTime today, {
    int firstWeekday = DateTime.monday,
    DateTime? firstDay,
  }) {
    final day = _date(today);
    return switch (range) {
      AnalyticsRange.week => AnalyticsPeriod.of(
        range,
        day.subtract(Duration(days: (day.weekday - firstWeekday) % 7)),
        firstWeekday: firstWeekday,
      ),
      AnalyticsRange.month => AnalyticsPeriod.of(
        range,
        DateTime.utc(day.year, day.month),
        firstWeekday: firstWeekday,
      ),
      AnalyticsRange.year => AnalyticsPeriod.of(
        range,
        DateTime.utc(day.year),
        firstWeekday: firstWeekday,
      ),
      AnalyticsRange.allYears => AnalyticsPeriod._(
        range,
        DateTime.utc((firstDay ?? day).year),
        DateTime.utc(day.year + 1),
        firstWeekday,
      ),
    };
  }

  /// The week, month or year of [range] that starts on [start].
  factory AnalyticsPeriod.of(
    AnalyticsRange range,
    DateTime start, {
    int firstWeekday = DateTime.monday,
  }) {
    final end = switch (range) {
      AnalyticsRange.week => DateTime.utc(
        start.year,
        start.month,
        start.day + 7,
      ),
      AnalyticsRange.month => DateTime.utc(start.year, start.month + 1),
      AnalyticsRange.year => DateTime.utc(start.year + 1),
      AnalyticsRange.allYears => throw ArgumentError.value(range),
    };
    return AnalyticsPeriod._(range, start, end, firstWeekday);
  }

  final AnalyticsRange range;
  final DateTime start;

  /// Exclusive.
  final DateTime end;
  final int firstWeekday;

  /// "All" covers everything and cannot step.
  bool get steps => range != AnalyticsRange.allYears;

  AnalyticsPeriod get previous => switch (range) {
    AnalyticsRange.week => AnalyticsPeriod.of(
      range,
      DateTime.utc(start.year, start.month, start.day - 7),
      firstWeekday: firstWeekday,
    ),
    AnalyticsRange.month => AnalyticsPeriod.of(
      range,
      DateTime.utc(start.year, start.month - 1),
      firstWeekday: firstWeekday,
    ),
    AnalyticsRange.year => AnalyticsPeriod.of(
      range,
      DateTime.utc(start.year - 1),
      firstWeekday: firstWeekday,
    ),
    AnalyticsRange.allYears => this,
  };

  AnalyticsPeriod get next => switch (range) {
    AnalyticsRange.allYears => this,
    _ => AnalyticsPeriod.of(range, end, firstWeekday: firstWeekday),
  };

  /// The period [steps] periods before this one.
  AnalyticsPeriod back(int steps) {
    var p = this;
    for (var i = 0; i < steps; i++) {
      p = p.previous;
    }
    return p;
  }

  /// How many periods there are from the one containing [firstDay] up to
  /// this one, both included; 1 without earlier intakes.
  int pagesBackTo(DateTime? firstDay) {
    var count = 1;
    for (var p = this; p.hasPrevious(firstDay); p = p.previous) {
      count++;
    }
    return count;
  }

  bool contains(DateTime day) {
    final d = _date(day);
    return !d.isBefore(start) && d.isBefore(end);
  }

  /// Whether a later period has begun by [today].
  bool hasNext(DateTime today) => steps && !_date(today).isBefore(end);

  /// Whether intakes exist before this period; [firstDay] is the first
  /// intake's day, null without intakes.
  bool hasPrevious(DateTime? firstDay) =>
      steps && firstDay != null && _date(firstDay).isBefore(start);

  /// Days of this period from its start through [today].
  int elapsedDays(DateTime today) {
    final last = _date(today).add(const Duration(days: 1));
    final until = last.isBefore(end) ? last : end;
    final days = until.difference(start).inDays;
    return days < 0 ? 0 : days;
  }

  List<Bucket> get buckets => switch (range) {
    AnalyticsRange.week || AnalyticsRange.month => [
      for (
        var d = start;
        d.isBefore(end);
        d = DateTime.utc(d.year, d.month, d.day + 1)
      )
        Bucket(d, DateTime.utc(d.year, d.month, d.day + 1), BucketUnit.day),
    ],
    AnalyticsRange.year => [
      for (var m = 1; m <= 12; m++)
        Bucket(
          DateTime.utc(start.year, m),
          DateTime.utc(start.year, m + 1),
          BucketUnit.month,
        ),
    ],
    AnalyticsRange.allYears => [
      for (var y = start.year; y < end.year; y++)
        Bucket(DateTime.utc(y), DateTime.utc(y + 1), BucketUnit.year),
    ],
  };

  /// Bounds for the daily-totals query. They compare against the UTC instant,
  /// so they keep two days of margin for intakes logged in other time zones;
  /// rows are trimmed by their local day afterwards. Null means unbounded.
  DateTime? get querySince =>
      steps ? DateTime(start.year, start.month, start.day - 2) : null;

  DateTime? get queryUntil =>
      steps ? DateTime(end.year, end.month, end.day + 2) : null;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsPeriod &&
      other.range == range &&
      other.start == start &&
      other.end == end &&
      other.firstWeekday == firstWeekday;

  @override
  int get hashCode => Object.hash(range, start, end, firstWeekday);
}

class Analytics {
  Analytics(this.period, this.buckets, this._days, this.today);

  /// Groups [rows] into the buckets of [period]; empty slots, including days
  /// that have not come yet, stay as empty buckets. [visible] limits which
  /// substances count; null means all.
  factory Analytics.build(
    AnalyticsPeriod period,
    List<DailyTotal> rows, {
    required DateTime today,
    Set<String>? visible,
  }) {
    final day = _date(today);
    final buckets = period.buckets;
    final inRange = [
      for (final r in rows)
        if (visible == null || visible.contains(r.substanceId))
          if (DateTime.parse('${r.day}T00:00:00Z') case final d
              when period.contains(d) && !d.isAfter(day))
            (day: d, row: r),
    ];

    for (final p in inRange) {
      final bucket = buckets.lastWhere((b) => !p.day.isBefore(b.start));
      final prev = bucket.bySubstance[p.row.substanceId];
      bucket.bySubstance[p.row.substanceId] = (
        total: (prev?.total ?? 0) + p.row.total,
        count: (prev?.count ?? 0) + p.row.count,
        dosed: (prev?.dosed ?? 0) + p.row.dosed,
      );
    }
    return Analytics(period, buckets, inRange, day);
  }

  final AnalyticsPeriod period;
  final List<Bucket> buckets;
  final List<({DateTime day, DailyTotal row})> _days;
  final DateTime today;

  AnalyticsRange get range => period.range;

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

    // A week has each weekday once, so its busiest weekday would only repeat
    // the busiest day.
    final Busiest? busiest = switch (range) {
      AnalyticsRange.week => null,
      AnalyticsRange.month => _busiest(perDay, BucketUnit.day),
      _ => _busiest(perDay, BucketUnit.month),
    };

    final int periodDays;
    if (range == AnalyticsRange.allYears) {
      periodDays = _days.isEmpty
          ? 0
          : today
                    .difference(
                      _days
                          .map((d) => d.day)
                          .reduce((a, b) => a.isBefore(b) ? a : b),
                    )
                    .inDays +
                1;
    } else {
      periodDays = period.elapsedDays(today);
    }

    return PeriodStats(
      total: total,
      activeDays: perDay.length,
      periodDays: periodDays,
      maxDay: maxDay,
      busiest: busiest,
      shares: [
        for (final MapEntry(:key, :value) in perSubstance.entries)
          (substanceId: key, share: value / total),
      ]..sort((a, b) => b.share.compareTo(a.share)),
    );
  }

  static Busiest? _busiest(Map<DateTime, int> perDay, BucketUnit by) {
    final slots = <int, int>{};
    for (final MapEntry(key: day, value: count) in perDay.entries) {
      final slot = by == BucketUnit.day ? day.weekday : day.month;
      slots[slot] = (slots[slot] ?? 0) + count;
    }
    if (slots.isEmpty) return null;
    final top = slots.values.fold(0, (a, b) => a > b ? a : b);
    return (
      by: by,
      indexes: [
        for (final MapEntry(:key, :value) in slots.entries)
          if (value == top) key,
      ]..sort(),
      count: top,
    );
  }
}

DateTime _date(DateTime d) => DateTime.utc(d.year, d.month, d.day);
