import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import 'analytics.dart';

extension AnalyticsLabels on AppLocalizations {
  String rangeLabel(AnalyticsRange range) => switch (range) {
    AnalyticsRange.twoWeeks => rangeTwoWeeks,
    AnalyticsRange.month => rangeMonth,
    AnalyticsRange.year => rangeYear,
    AnalyticsRange.allYears => rangeAllYears,
  };

  /// Sparse axis labels, counted back from the latest bar so "now" is always
  /// labelled.
  String bucketAxisLabel(Bucket bucket, int index, int count) {
    final every = switch (bucket.unit) {
      BucketUnit.day => count > 14 ? 5 : 2,
      BucketUnit.month => 3,
      BucketUnit.year => (count / 6).ceil(),
    };
    if ((count - 1 - index) % every != 0) return '';
    final d = bucket.start;
    return switch (bucket.unit) {
      BucketUnit.day => DateFormat.d(localeName).format(d),
      BucketUnit.month => DateFormat.LLL(localeName).format(d),
      BucketUnit.year => DateFormat.y(localeName).format(d),
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

  String monthName(int month) =>
      DateFormat.LLLL(localeName).format(DateTime(2024, month));
}
