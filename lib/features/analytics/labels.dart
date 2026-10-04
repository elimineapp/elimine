import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import 'analytics.dart';

extension AnalyticsLabels on AppLocalizations {
  String rangeLabel(AnalyticsRange range) => switch (range) {
    AnalyticsRange.week => rangeWeek,
    AnalyticsRange.month => rangeMonth,
    AnalyticsRange.year => rangeYear,
    AnalyticsRange.allYears => rangeAllYears,
  };

  /// Axis labels: every weekday of a week, the 1st and every 5th day of a
  /// month, quarters of a year, and about six of all years counted back from
  /// the latest so "now" is always labelled.
  String bucketAxisLabel(Bucket bucket, int index, int count) {
    final d = bucket.start;
    return switch (bucket.unit) {
      BucketUnit.day when count <= 7 => DateFormat.E(localeName).format(d),
      BucketUnit.day =>
        d.day == 1 || d.day % 5 == 0 ? DateFormat.d(localeName).format(d) : '',
      BucketUnit.month =>
        d.month % 3 == 1 ? DateFormat.LLL(localeName).format(d) : '',
      BucketUnit.year =>
        (count - 1 - index) % (count / 6).ceil() == 0
            ? DateFormat.y(localeName).format(d)
            : '',
    };
  }

  /// The displayed period, e.g. "Sep 28 – Oct 4", "October 2026" or "2026".
  String periodTitle(AnalyticsPeriod period, DateTime today) {
    final first = period.start;
    final last = period.end.subtract(const Duration(days: 1));
    return switch (period.range) {
      AnalyticsRange.week =>
        first.year == today.year && last.year == today.year
            ? '${DateFormat.MMMd(localeName).format(first)} – '
                  '${DateFormat.MMMd(localeName).format(last)}'
            : '${DateFormat.yMMMd(localeName).format(first)} – '
                  '${DateFormat.yMMMd(localeName).format(last)}',
      AnalyticsRange.month => _capitalized(
        DateFormat.yMMMM(localeName).format(first),
      ),
      AnalyticsRange.year => DateFormat.y(localeName).format(first),
      AnalyticsRange.allYears =>
        first.year == last.year
            ? '${first.year}'
            : '${first.year} – ${last.year}',
    };
  }

  String bucketTitle(Bucket bucket) {
    final d = bucket.start;
    return switch (bucket.unit) {
      BucketUnit.day => DateFormat.MMMEd(localeName).format(d),
      BucketUnit.month => DateFormat.yMMMM(localeName).format(d),
      BucketUnit.year => DateFormat.y(localeName).format(d),
    };
  }

  String weekdayName(int weekday) =>
      // 2024-01-01 was a Monday.
      DateFormat.EEEE(localeName).format(DateTime(2024, 1, weekday));

  /// The weekday name as a standalone title, e.g. "Monday" or "Понедельник".
  String weekdayTitle(int weekday) => _capitalized(weekdayName(weekday));

  String monthName(int month) =>
      DateFormat.LLLL(localeName).format(DateTime(2024, month));
}

String _capitalized(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
