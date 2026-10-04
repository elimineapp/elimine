import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/appearance.dart';
import '../../core/db/database.dart';
import '../../core/l10n/format.dart';
import '../../l10n/app_localizations.dart';
import '../analytics/analytics.dart';
import '../analytics/analytics_queries.dart';
import '../analytics/bar_chart.dart';
import '../analytics/labels.dart';
import '../analytics/period_bar.dart';

/// Dose totals of one substance in its own unit for a calendar week, month or
/// year: per day for a week or a month, daily average per month for a year. Intakes without a dose add
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
    AnalyticsRange.week,
    AnalyticsRange.month,
    AnalyticsRange.year,
  ];

  AnalyticsRange _range = AnalyticsRange.week;

  /// How many periods back from the current one the chart shows.
  int _back = 0;
  final _pages = PageController();

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

  List<DailyTotal> _rows(WidgetRef ref, AnalyticsPeriod p) =>
      ref
          .watch(
            dailyTotalsProvider((
              since: p.querySince,
              until: p.queryUntil,
              substanceId: widget.substance.id,
            )),
          )
          .value ??
      const [];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final substance = widget.substance;
    final now = widget.clock();
    final weekStart = ref.watch(weekStartProvider).value ?? DateTime.monday;
    final firstDay = ref.watch(firstIntakeDayProvider(substance.id)).value;
    final current = AnalyticsPeriod.current(
      _range,
      now,
      firstWeekday: weekStart,
    );
    final pages = current.pagesBackTo(firstDay);
    final back = _back.clamp(0, pages - 1);
    final period = current.back(back);
    final shown = _DoseChart(
      substance,
      Analytics.build(period, _rows(ref, period), today: now),
      l,
    );

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
          onSelectionChanged: (s) {
            setState(() => _range = s.single);
            _toCurrent();
          },
        ),
        const SizedBox(height: 8),
        PeriodBar(
          label: l.periodTitle(period, now),
          onPrevious: back < pages - 1 ? () => _goTo(back + 1) : null,
          onNext: back > 0 ? () => _goTo(back - 1) : null,
          onToday: _toCurrent,
        ),
        const SizedBox(height: 8),
        Text(shown.title, style: theme.textTheme.titleSmall),
        PeriodPages(
          // A new range starts its own set of pages.
          key: ValueKey(_range),
          controller: _pages,
          count: pages,
          height: 200,
          onPageChanged: (back) => setState(() => _back = back),
          itemBuilder: (context, back) {
            final p = current.back(back);
            return Consumer(
              builder: (context, ref, _) => _DoseChart(
                substance,
                Analytics.build(p, _rows(ref, p), today: now),
                l,
              ).chart(context),
            );
          },
        ),
      ],
    );
  }
}

/// Dose sums, daily averages or intake counts of one substance for one
/// period, with the matching title.
class _DoseChart {
  _DoseChart(this.substance, this.analytics, this.l) {
    final id = substance.id;
    final buckets = analytics.buckets;
    counting =
        buckets.any((b) => b.countFor(id) > 0) &&
        buckets.every((b) => b.countFor(id) == b.undosedFor(id));
    averaged = !counting && analytics.unit != BucketUnit.day;
  }

  final Substance substance;
  final Analytics analytics;
  final AppLocalizations l;
  late final bool counting;
  late final bool averaged;

  String get title {
    final unit = substance.unit;
    return switch ((counting, averaged, unit.isEmpty)) {
      (true, _, _) => l.intakesChartTitle,
      (false, true, true) => l.doseChartDailyAverageNoUnit,
      (false, true, false) => l.doseChartDailyAverage(unit),
      (false, false, true) => l.doseChartPerDayNoUnit,
      (false, false, false) => l.doseChartPerDay(unit),
    };
  }

  double _value(Bucket b) {
    final id = substance.id;
    if (counting) return b.countFor(id).toDouble();
    final total = b.totalFor(id);
    return averaged ? total / b.elapsedDays(analytics.today) : total;
  }

  String? _note(Bucket b) {
    final undosed = b.undosedFor(substance.id);
    return counting || undosed == 0 ? null : l.tooltipWithoutDose(undosed);
  }

  Widget chart(BuildContext context) {
    final buckets = analytics.buckets;
    final color = context.substanceColorOf(substance.color);
    return ElimineBarChart(
      formatValue: l.amount,
      formatTooltipValue: counting
          ? (v) => l.tooltipIntakes(v.round())
          : (v) => l.dose(double.parse(v.toStringAsFixed(2)), substance.unit),
      integerValues: counting,
      bars: [
        for (final (i, bucket) in buckets.indexed)
          ChartBar(
            axisLabel: l.bucketAxisLabel(bucket, i, buckets.length),
            tooltipTitle: l.bucketTitle(bucket),
            segments: [ChartSegment(substance.name, color, _value(bucket))],
            note: _note(bucket),
          ),
      ],
    );
  }
}
