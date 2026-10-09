# Tasks

## 1. Axis calculation

- [x] 1.1 In `lib/features/analytics/bar_chart.dart`, rename `_axis` to a public `chartAxis` marked `@visibleForTesting` and update its caller; verify `flutter analyze` reports no issues
- [x] 1.2 Rewrite `chartAxis(max, integer)` to return the top (next multiple of `10^(digits − 2)` strictly above `max`; whole when counting) and the interval: 1 for counts with a top of 5 or less, otherwise `top / 2` with the count top rounded up to even while the unit is 1; empty periods give (2, 1) for counts and (1, 0.5) for doses; guard the division with an epsilon and round the top to the unit's decimals; update its doc comment; verify with the tests in 1.4
- [x] 1.3 In `ElimineBarChart.build`, drop the plot-height argument and the label filter from the previous attempt, pass `chartAxis` the larger of the tallest bar and `total × h / (h − 9)` for bars with a note, and keep deriving the dot size from the final top; verify the existing note-dot test in `test/bar_chart_test.dart` still passes (dot inside `maxY`)
- [x] 1.4 Replace the `chartAxis` tests in `test/bar_chart_test.dart` with (max → top, interval): counts 0 → (2, 1), 1 → (2, 1), 2 → (3, 1), 3 → (4, 1), 4 → (5, 1), 5 → (6, 3), 9 → (10, 5), 10 → (12, 6), 51 → (52, 26), 99 → (100, 50), 100 → (110, 55), 101 → (110, 55), 1001 → (1100, 550); doses 0 → (1, 0.5), 250 → (260, 130), 0.3 → (0.31, 0.155), 7.5 → (7.6, 3.8); a widget test that a count chart with a 101 bar labels exactly 0, 55 and 110 and one with a 2 bar labels exactly 0, 1, 2 and 3, and that a 250 bar with a note gets a top of 270; verify `flutter test test/bar_chart_test.dart` passes
- [x] 1.5 Make the top the first multiple at or above the tallest bar (not strictly above), with a count top of at least 2; use `ceil(max / unit − ε)`; update the doc comment and the `chartAxis` tests (counts 1 → (2, 1), 2 → (2, 1), 3 → (3, 1), 5 → (5, 1), 6 → (6, 3), 10 → (10, 5), 52 → (52, 26), 100 → (100, 50); doses 250 → (250, 125), 251 → (260, 130), 0.28 → (0.28, 0.14)) and the small-count label test (3 → 0, 1, 2, 3); verify `flutter test test/bar_chart_test.dart` passes
- [x] 1.6 Drop the count floor of 2: a single intake and an empty period give (1, 1); update the doc comment, the `chartAxis` tests (0 → (1, 1), 1 → (1, 1)) and the specs; verify `flutter test test/bar_chart_test.dart` passes

## 2. Verification

- [x] 2.1 Run `task check` (format, analyzer, tests) and verify it passes
- [x] 2.2 On the emulator with the demo data, verify: Analytics → "Year" 2026 is labeled 0, 55, 110 (or the values for its actual busiest month) with the May bar just under the top; Nicotine → "Year" is labeled 0, 25, 50 for its 49-intake April; a dose chart with a "no dose" dot shows the dot under the top; Analytics → "Month" October 2026 (busiest day 2) is labeled 0, 1, 2 with the busiest days reaching the top; Ibuprofen → "Week" Aug 31 – Sep 6 (one intake without a dose) is labeled 0, 1
