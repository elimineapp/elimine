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
import 'period_bar.dart';

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

  /// How many periods back from the current one the chart shows.
  int _back = 0;
  final _pages = PageController();
  final Set<String> _hidden = {};

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int back) => _pages.animateToPage(
    back,
    duration: periodPageDuration,
    curve: periodPageCurve,
  );

  void _toCurrent() {
    setState(() => _back = 0);
    if (_pages.hasClients) _pages.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = widget.clock();
    final substances = {
      for (final s
          in ref.watch(allSubstancesProvider).value ?? const <Substance>[])
        s.id: s,
    };
    final weekStart = ref.watch(weekStartProvider).value ?? DateTime.monday;
    final firstDay = ref.watch(firstIntakeDayProvider(null)).value;
    final current = AnalyticsPeriod.current(
      _range,
      now,
      firstWeekday: weekStart,
      firstDay: firstDay,
    );
    final pages = current.pagesBackTo(firstDay);
    final back = _back.clamp(0, pages - 1);
    final period = current.back(back);
    final onPrevious = back < pages - 1 ? () => _goTo(back + 1) : null;
    final onNext = back > 0 ? () => _goTo(back - 1) : null;

    final rows =
        ref
            .watch(
              dailyTotalsProvider((
                since: period.querySince,
                until: period.queryUntil,
                substanceId: null,
              )),
            )
            .value ??
        const [];

    // Stack and list in palette order: neighbours there are validated to
    // stay distinguishable.
    final present = <Substance>[
      for (final id in Analytics.build(period, rows, today: now).substanceIds)
        ?substances[id],
    ]..sort(_byPalette);
    final visible = [
      for (final s in present)
        if (!_hidden.contains(s.id)) s,
    ];
    // Neighbouring pages stack every shown substance in the same order.
    final stacked = <Substance>[
      for (final s in substances.values)
        if (!_hidden.contains(s.id)) s,
    ]..sort(_byPalette);
    final analytics = Analytics.build(
      period,
      rows,
      today: now,
      visible: {for (final s in visible) s.id},
    );
    final stats = analytics.stats();

    String name(Substance s) =>
        s.archivedAt == null ? s.name : l.archivedSuffix(s.name);

    Widget chart(BuildContext context, int back) {
      final p = current.back(back);
      return Consumer(
        builder: (context, ref, _) {
          final rows =
              ref
                  .watch(
                    dailyTotalsProvider((
                      since: p.querySince,
                      until: p.queryUntil,
                      substanceId: null,
                    )),
                  )
                  .value ??
              const [];
          final buckets = Analytics.build(p, rows, today: now).buckets;
          return ElimineBarChart(
            bars: [
              for (final (i, bucket) in buckets.indexed)
                ChartBar(
                  axisLabel: l.bucketAxisLabel(bucket, i, buckets.length),
                  tooltipTitle: l.bucketTitle(bucket),
                  segments: [
                    for (final s in stacked)
                      if (bucket.countFor(s.id) > 0)
                        ChartSegment(
                          name(s),
                          context.substanceColorOf(s.color),
                          bucket.countFor(s.id).toDouble(),
                        ),
                  ],
                ),
            ],
            integerValues: true,
            formatValue: (v) => v.toInt().toString(),
            formatTooltipValue: (v) => l.tooltipIntakes(v.toInt()),
          );
        },
      );
    }

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
            onSelectionChanged: (s) {
              setState(() => _range = s.single);
              _toCurrent();
            },
          ),
          const SizedBox(height: 8),
          PeriodBar(
            label: l.periodTitle(period, now),
            arrows: period.steps,
            onPrevious: onPrevious,
            onNext: onNext,
            onToday: _toCurrent,
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
          PeriodPages(
            // A new range starts its own set of pages.
            key: ValueKey(_range),
            controller: _pages,
            count: pages,
            height: 200,
            onPageChanged: (back) => setState(() => _back = back),
            itemBuilder: chart,
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

int _byPalette(Substance a, Substance b) {
  final byColor = substanceColorOrder(a.color)
      .compareTo(substanceColorOrder(b.color));
  return byColor != 0 ? byColor : a.sortOrder.compareTo(b.sortOrder);
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
          // A long value (several tied weekdays) wraps instead of squeezing
          // the label down to a column of single letters.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.6,
            ),
            child: Text(
              value,
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
