import 'package:elimine/features/analytics/bar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a count axis ends at two significant digits from the tallest bar', () {
    for (final (max, top, interval) in [
      (0.0, 1.0, 1.0),
      (1.0, 1.0, 1.0),
      (2.0, 2.0, 1.0),
      (3.0, 3.0, 1.0),
      (5.0, 5.0, 1.0),
      (6.0, 6.0, 3.0),
      (9.0, 10.0, 5.0),
      (10.0, 10.0, 5.0),
      (51.0, 52.0, 26.0),
      (52.0, 52.0, 26.0),
      (99.0, 100.0, 50.0),
      (100.0, 100.0, 50.0),
      (101.0, 110.0, 55.0),
      (1001.0, 1100.0, 550.0),
    ]) {
      expect(chartAxis(max, true), (top, interval), reason: 'max $max');
    }
  });

  test('a dose axis ends at two significant digits from the tallest bar', () {
    for (final (max, top) in [
      (0.0, 1.0),
      (250.0, 250.0),
      (251.0, 260.0),
      (0.28, 0.28),
      (0.3, 0.3),
      (7.5, 7.5),
      (7.51, 7.6),
    ]) {
      expect(chartAxis(max, false), (top, top / 2), reason: 'max $max');
    }
  });

  Widget chart(List<ChartBar> bars, {bool integerValues = false}) =>
      MaterialApp(
        home: Scaffold(
          body: ElimineBarChart(
            integerValues: integerValues,
            formatValue: (v) => v.toStringAsFixed(0),
            bars: bars,
          ),
        ),
      );

  testWidgets('a count axis is labeled halfway, or at every small count', (
    tester,
  ) async {
    Future<Iterable<String?>> labels(double max) async {
      await tester.pumpWidget(
        chart(integerValues: true, [
          ChartBar(
            axisLabel: '',
            tooltipTitle: 'May',
            segments: [ChartSegment('X', const Color(0xFFE34948), max)],
          ),
        ]),
      );
      return tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((s) => s != null && s.isNotEmpty);
    }

    expect(await labels(101), unorderedEquals(['0', '55', '110']));
    expect(await labels(3), unorderedEquals(['0', '1', '2', '3']));
  });

  testWidgets('the axis leaves room for the dot above the tallest bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      chart(const [
        ChartBar(
          axisLabel: '',
          tooltipTitle: 'Mon',
          segments: [ChartSegment('X', Color(0xFFE34948), 250)],
          note: '1 intake',
        ),
      ]),
    );

    expect(tester.widget<BarChart>(find.byType(BarChart)).data.maxY, 270);
  });

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
