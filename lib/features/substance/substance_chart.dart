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
/// ranges, daily average per month for the year. Intakes without a dose add
/// nothing to the sums and mark their bar with a dot; a range where no intake
/// has a dose counts intakes instead (per day, or per month for the year).
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
    final id = substance.id;
    final buckets = analytics.buckets;
    final counting =
        buckets.any((b) => b.countFor(id) > 0) &&
        buckets.every((b) => b.countFor(id) == b.undosedFor(id));
    final averaged = !counting && analytics.unit != BucketUnit.day;
    final unit = substance.unit;
    final color = context.substanceColorOf(substance.color);

    final title = switch ((counting, averaged, unit.isEmpty)) {
      (true, _, _) => l.intakesChartTitle,
      (false, true, true) => l.doseChartDailyAverageNoUnit,
      (false, true, false) => l.doseChartDailyAverage(unit),
      (false, false, true) => l.doseChartPerDayNoUnit,
      (false, false, false) => l.doseChartPerDay(unit),
    };

    double value(Bucket b) {
      if (counting) return b.countFor(id).toDouble();
      final total = b.totalFor(id);
      return averaged ? total / b.elapsedDays(analytics.today) : total;
    }

    String? note(Bucket b) {
      final undosed = b.undosedFor(id);
      return counting || undosed == 0 ? null : l.tooltipWithoutDose(undosed);
    }

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
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ElimineBarChart(
          formatValue: l.amount,
          formatTooltipValue: counting
              ? (v) => l.tooltipIntakes(v.round())
              : (v) => l.dose(double.parse(v.toStringAsFixed(2)), unit),
          integerValues: counting,
          bars: [
            for (final (i, bucket) in buckets.indexed)
              ChartBar(
                axisLabel: l.bucketAxisLabel(bucket, i, buckets.length),
                tooltipTitle: l.bucketTitle(bucket),
                segments: [ChartSegment(substance.name, color, value(bucket))],
                note: note(bucket),
              ),
          ],
        ),
      ],
    );
  }
}
