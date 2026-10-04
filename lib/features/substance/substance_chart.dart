import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/appearance.dart';
import '../../core/db/database.dart';
import '../../core/l10n/format.dart';
import '../../l10n/app_localizations.dart';
import '../analytics/analytics.dart';
import '../analytics/bar_chart.dart';
import '../analytics/labels.dart';

/// Dose totals of one substance in its own unit: per day for the short
/// ranges, daily average per month for the year.
class SubstanceChart extends ConsumerStatefulWidget {
  const SubstanceChart({
    super.key,
    required this.substance,
    this.clock = DateTime.now,
  });

  final Substance substance;
  final DateTime Function() clock;

  @override
  ConsumerState<SubstanceChart> createState() => _SubstanceChartState();
}

class _SubstanceChartState extends ConsumerState<SubstanceChart> {
  static const _ranges = [
    AnalyticsRange.twoWeeks,
    AnalyticsRange.month,
    AnalyticsRange.year,
  ];

  AnalyticsRange _range = AnalyticsRange.twoWeeks;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final substance = widget.substance;
    final now = widget.clock();
    final rows =
        ref
            .watch(
              dailyTotalsProvider((
                since: rangeQuerySince(_range, now),
                substanceId: substance.id,
              )),
            )
            .value ??
        const [];
    final analytics = Analytics.build(_range, rows, today: now);
    final averaged = analytics.unit != BucketUnit.day;
    final color = context.substanceColorOf(substance.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<AnalyticsRange>(
          showSelectedIcon: false,
          segments: [
            for (final r in _ranges)
              ButtonSegment(value: r, label: Text(l.rangeLabel(r))),
          ],
          selected: {_range},
          onSelectionChanged: (s) => setState(() => _range = s.single),
        ),
        const SizedBox(height: 16),
        Text(
          averaged
              ? l.doseChartDailyAverage(substance.unit)
              : l.doseChartPerDay(substance.unit),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ElimineBarChart(
          formatValue: l.amount,
          formatTooltipValue: (v) =>
              l.dose(double.parse(v.toStringAsFixed(2)), substance.unit),
          bars: [
            for (final (i, bucket) in analytics.buckets.indexed)
              ChartBar(
                axisLabel: l.bucketAxisLabel(
                  bucket,
                  i,
                  analytics.buckets.length,
                ),
                tooltipTitle: l.bucketTitle(bucket),
                segments: [
                  ChartSegment(
                    substance.name,
                    color,
                    averaged
                        ? bucket.totalFor(substance.id) /
                              bucket.elapsedDays(analytics.today)
                        : bucket.totalFor(substance.id),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
