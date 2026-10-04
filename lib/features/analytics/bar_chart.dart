import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartSegment {
  const ChartSegment(this.label, this.color, this.value);

  final String label;
  final Color color;
  final double value;
}

class ChartBar {
  const ChartBar({
    required this.axisLabel,
    required this.tooltipTitle,
    required this.segments,
    this.note,
  });

  /// Shown under the bar; empty to skip, so labels stay sparse.
  final String axisLabel;
  final String tooltipTitle;

  /// Bottom to top. One segment is a plain bar.
  final List<ChartSegment> segments;

  /// Something the bar's value leaves out, e.g. "1 without dose": marked with
  /// a dot above the bar and added as the last tooltip line.
  final String? note;

  double get total => segments.fold(0, (sum, s) => sum + s.value);
}

/// Bars anchored to a zero baseline with a recessive grid, 4px rounded tops,
/// a 2px surface gap between stacked segments and a tooltip on tap. Empty
/// periods stay as gaps rather than being smoothed over. A tap pins the
/// tooltip to a bar; tapping it again or elsewhere clears it. A bar with a
/// [ChartBar.note] gets a dot just above it (or above the baseline).
class ElimineBarChart extends StatefulWidget {
  const ElimineBarChart({
    super.key,
    required this.bars,
    required this.formatValue,
    this.formatTooltipValue,
    this.integerValues = false,
    this.height = 200,
  });

  final List<ChartBar> bars;

  /// Axis labels.
  final String Function(double value) formatValue;

  /// Tooltip values, e.g. with a unit; defaults to [formatValue].
  final String Function(double value)? formatTooltipValue;

  /// Counts: keep axis steps whole.
  final bool integerValues;
  final double height;

  @override
  State<ElimineBarChart> createState() => _ElimineBarChartState();
}

class _ElimineBarChartState extends State<ElimineBarChart> {
  int? _selected;

  @override
  void didUpdateWidget(ElimineBarChart old) {
    super.didUpdateWidget(old);
    if (old.bars.length != widget.bars.length) _selected = null;
  }

  static const _bottomTitles = 24.0;
  static const _dot = 6.0;
  static const _dotGap = 3.0;

  @override
  Widget build(BuildContext context) {
    final bars = widget.bars;
    final formatValue = widget.formatValue;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final axisStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final surface = scheme.surface;
    var (maxY, step) = _axis(
      bars.map((b) => b.total).fold(0.0, math.max),
      widget.integerValues,
    );
    // Chart units per pixel, so the dot keeps its size at any scale; bump
    // the axis by a step when a dot would stick out of the top.
    double unitsPerPx() => maxY / (widget.height - _bottomTitles);
    final dotSpan = (_dotGap + _dot) * unitsPerPx();
    if (bars.any((b) => b.note != null && b.total + dotSpan > maxY)) {
      maxY += step;
    }
    final upp = unitsPerPx();

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = (constraints.maxWidth - 40) / math.max(bars.length, 1);
          final barWidth = (slot * 0.6).clamp(3.0, 28.0);

          return BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: step,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: step,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(formatValue(value), style: axisStyle),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: _bottomTitles,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        bars[value.toInt()].axisLabel,
                        style: axisStyle,
                      ),
                    ),
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                handleBuiltInTouches: false,
                // Dots and short bars are small targets.
                touchExtraThreshold: const EdgeInsets.only(top: 16),
                touchCallback: (event, response) {
                  if (event is! FlTapUpEvent) return;
                  final hit = response?.spot?.touchedBarGroupIndex;
                  setState(() => _selected = hit == _selected ? null : hit);
                },
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      _tooltip(bars[group.x], theme),
                ),
              ),
              barGroups: [
                for (final (i, bar) in bars.indexed)
                  BarChartGroupData(
                    x: i,
                    // The dot shares the bar's column instead of sitting
                    // beside it.
                    groupVertically: true,
                    barRods: [
                      _rod(bar, barWidth, surface),
                      if (bar.note != null) _dotRod(bar, barWidth, upp),
                    ],
                    // On the topmost rod, so the tooltip clears the dot.
                    showingTooltipIndicators: i == _selected
                        ? [bar.note != null ? 1 : 0]
                        : const [],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  BarChartRodData _rod(ChartBar bar, double width, Color surface) {
    const radius = BorderRadius.vertical(top: Radius.circular(4));
    final visible = [
      for (final s in bar.segments)
        if (s.value > 0) s,
    ];
    if (visible.length <= 1) {
      return BarChartRodData(
        toY: bar.total,
        width: width,
        color: visible.firstOrNull?.color ?? Colors.transparent,
        borderRadius: radius,
      );
    }
    var from = 0.0;
    return BarChartRodData(
      toY: bar.total,
      width: width,
      color: Colors.transparent,
      borderRadius: radius,
      rodStackItems: [
        for (final s in visible)
          BarChartRodStackItem(
            from,
            from += s.value,
            s.color,
            // Half the 2px gap on each side of every segment.
            borderSide: BorderSide(color: surface, width: 1),
          ),
      ],
    );
  }

  BarChartRodData _dotRod(ChartBar bar, double barWidth, double upp) {
    final from = bar.total + _dotGap * upp;
    final size = math.min(_dot, barWidth);
    return BarChartRodData(
      fromY: from,
      toY: from + size * upp,
      width: size,
      color: bar.segments.firstOrNull?.color,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  BarTooltipItem _tooltip(ChartBar bar, ThemeData theme) {
    final style = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onInverseSurface,
    );
    final format = widget.formatTooltipValue ?? widget.formatValue;
    final named = bar.segments.length > 1;
    final lines = [
      for (final s in bar.segments.reversed)
        if (s.value > 0) s,
    ];
    return BarTooltipItem(
      bar.tooltipTitle,
      style.copyWith(fontWeight: FontWeight.w600),
      textAlign: TextAlign.start,
      children: [
        if (lines.isEmpty && bar.note == null)
          TextSpan(text: '\n${format(0)}', style: style),
        for (final s in lines) ...[
          TextSpan(
            text: '\n● ',
            style: style.copyWith(color: s.color),
          ),
          TextSpan(
            text: named ? '${s.label}: ${format(s.value)}' : format(s.value),
            style: style,
          ),
        ],
        if (bar.note case final note?) TextSpan(text: '\n$note', style: style),
      ],
    );
  }
}

/// A "nice" axis top and step: about four gridlines at 1/2/2.5/5 × 10ⁿ.
(double, double) _axis(double max, bool integer) {
  if (max <= 0) return (integer ? 4 : 1, integer ? 1 : 0.25);
  final raw = max / 4;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  var step = [
    1,
    2,
    2.5,
    5,
    10,
  ].map((m) => m * magnitude).firstWhere((s) => s >= raw);
  if (integer) {
    // Whole steps and at least four of them, so one or two intakes do not
    // hit the top of the chart.
    step = math.max(1, step.ceilToDouble());
    return (math.max(4, (max / step).ceil()) * step, step);
  }
  return ((max / step).ceil() * step, step);
}
