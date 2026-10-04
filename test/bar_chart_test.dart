import 'package:elimine/features/analytics/bar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a bar with a note gets a dot above it and a tooltip line', (
    tester,
  ) async {
    const red = Color(0xFFE34948);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ElimineBarChart(
            formatValue: (v) => v.toStringAsFixed(0),
            bars: const [
              ChartBar(
                axisLabel: '',
                tooltipTitle: 'Mon',
                segments: [ChartSegment('X', red, 250)],
                note: '2 intakes',
              ),
              ChartBar(
                axisLabel: '',
                tooltipTitle: 'Tue',
                segments: [ChartSegment('X', red, 0)],
                note: '2 intakes',
              ),
              ChartBar(
                axisLabel: '',
                tooltipTitle: 'Wed',
                segments: [ChartSegment('X', red, 100)],
              ),
            ],
          ),
        ),
      ),
    );

    final data = tester.widget<BarChart>(find.byType(BarChart)).data;
    final [mixed, undosedOnly, plain] = data.barGroups;

    expect(mixed.groupVertically, isTrue);
    expect(mixed.barRods, hasLength(2));
    final dot = mixed.barRods[1];
    expect(dot.fromY, greaterThan(250));
    expect(dot.toY, lessThanOrEqualTo(data.maxY));
    expect(dot.color, red);

    expect(undosedOnly.barRods[1].fromY, greaterThan(0));
    expect(plain.barRods, hasLength(1));

    String tooltip(BarChartGroupData group) {
      final item = data.barTouchData.touchTooltipData.getTooltipItem(
        group,
        group.x,
        group.barRods.last,
        group.barRods.length - 1,
      )!;
      return [
        item.text,
        for (final c in item.children!) c.toPlainText(),
      ].join();
    }

    expect(tooltip(mixed), contains('250'));
    expect(tooltip(mixed), endsWith('\n2 intakes'));
    // No misleading zero when the day only had intakes without a dose.
    expect(tooltip(undosedOnly), 'Tue\n2 intakes');
  });
}
