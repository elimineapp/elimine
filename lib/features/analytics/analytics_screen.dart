import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/appearance.dart';
import '../../core/db/database.dart';
import '../../l10n/app_localizations.dart';
import 'analytics.dart';
import 'bar_chart.dart';
import 'labels.dart';

/// Cross-substance view: intake counts, since units differ between
/// substances and cannot be summed.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsRange _range = AnalyticsRange.month;
  final Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = widget.clock();
    final substances = {
      for (final s in ref.watch(allSubstancesProvider).value ?? const [])
        s.id: s,
    };
    final rows =
        ref
            .watch(
              dailyTotalsProvider((
                since: rangeQuerySince(_range, now),
                substanceId: null,
              )),
            )
            .value ??
        const [];

    // Stack and list in palette order: neighbours there are validated to
    // stay distinguishable.
    final present =
        [
          for (final id in Analytics.build(
            _range,
            rows,
            today: now,
          ).substanceIds)
            ?substances[id],
        ]..sort((a, b) {
          final byColor = substanceColorOrder(a.color)
              .compareTo(substanceColorOrder(b.color));
          return byColor != 0 ? byColor : a.sortOrder.compareTo(b.sortOrder);
        });
    final visible = [
      for (final s in present)
        if (!_hidden.contains(s.id)) s,
    ];
    final analytics = Analytics.build(
      _range,
      rows,
      today: now,
      visible: {for (final s in visible) s.id},
    );
    final stats = analytics.stats();

    String name(Substance s) =>
        s.archivedAt == null ? s.name : l.archivedSuffix(s.name);

    final bars = [
      for (final (i, bucket) in analytics.buckets.indexed)
        ChartBar(
          axisLabel: l.bucketAxisLabel(bucket, i, analytics.buckets.length),
          tooltipTitle: l.bucketTitle(bucket),
          segments: [
            for (final s in visible)
              ChartSegment(
                name(s),
                context.substanceColorOf(s.color),
                (bucket.bySubstance[s.id]?.count ?? 0).toDouble(),
              ),
          ],
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.analyticsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SegmentedButton<AnalyticsRange>(
            showSelectedIcon: false,
            segments: [
              for (final r in AnalyticsRange.values)
                ButtonSegment(value: r, label: Text(l.rangeLabel(r))),
            ],
            selected: {_range},
            onSelectionChanged: (s) => setState(() => _range = s.single),
          ),
          if (present.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              key: const Key('substanceFilters'),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in present)
                  FilterChip(
                    avatar: CircleAvatar(
                      backgroundColor: context.substanceColorOf(s.color),
                    ),
                    showCheckmark: false,
                    label: Text(name(s)),
                    selected: !_hidden.contains(s.id),
                    onSelected: (on) => setState(
                      () => on ? _hidden.remove(s.id) : _hidden.add(s.id),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(l.intakesChartTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ElimineBarChart(
            bars: bars,
            integerValues: true,
            formatValue: (v) => v.toInt().toString(),
            formatTooltipValue: (v) => l.tooltipIntakes(v.toInt()),
          ),
          if (stats.total == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.noDataInRange,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else ...[
            const SizedBox(height: 16),
            _Metric(l.metricTotal, '${stats.total}'),
            _Metric(
              l.metricActiveDays,
              l.metricActiveDaysValue(stats.activeDays, stats.periodDays),
            ),
            if (stats.maxDay case final max?)
              _Metric(
                l.metricMaxDay,
                l.metricMaxDayValue(
                  max.count,
                  (max.day.year == now.year
                          ? DateFormat.MMMd(l.localeName)
                          : DateFormat.yMMMd(l.localeName))
                      .format(max.day),
                ),
              ),
            if (stats.busiest case final busiest?)
              busiest.by == BucketUnit.day
                  ? _Metric(
                      l.metricBusiestWeekday,
                      busiest.indexes.map(l.weekdayName).join(', '),
                    )
                  : _Metric(
                      l.metricBusiestMonth,
                      busiest.indexes.map(l.monthName).join(', '),
                    ),
            if (visible.length > 1) ...[
              const SizedBox(height: 16),
              Text(l.metricShare, style: theme.textTheme.titleSmall),
              for (final share in stats.shares)
                if (substances[share.substanceId] case final s?)
                  _Metric(
                    name(s),
                    NumberFormat.percentPattern(l.localeName)
                        .format(share.share),
                    color: context.substanceColorOf(s.color),
                  ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        spacing: 8,
        children: [
          if (color case final c?)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
