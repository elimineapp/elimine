# Proposal

## Why

Bar charts often end their value axis far above the tallest bar: a year whose busiest month has 101 intakes is drawn on a 0–200 axis, so the bars fill half the chart. Count charts force four gridline steps even when fewer reach past the tallest bar, and every chart ends its axis on a "nice" step (1, 2, 2.5 or 5 × 10ⁿ), so even without that rule the gap can be half the chart (101 → 150). Dose charts add yet another whole step when a bar's "no dose" dot would not fit (300 mg → 0–400).

## What Changes

- Every bar chart ends its value axis at the tallest bar rounded up to two significant digits, and labels that top: 101 intakes get a 0–110 axis rather than 0–200, and 100 intakes a 0–100 axis with the tallest bar reaching the top.
- One gridline sits halfway, labeled with its value (55 for a 0–110 axis); round steps such as 50 are no longer guaranteed.
- When counting, the top and the halfway value are whole numbers. Small counts (a top of 5 or less) get a gridline at every whole number instead of the halfway one: 3 intakes give 0–1–2–3 rather than 0–2–4. The old floor of 4 goes away: a single intake gets 0–1, reaching the top like any tallest bar.
- When the tallest bar carries a "no dose" dot, the top rounds up from the bar plus its dot, so the dot fits without adding a whole step.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `analytics`: a new requirement for where the intake chart's value axis ends and which gridlines it labels.
- `substance-chart`: the dose chart (and its intake-count mode) gains the same axis rule, with room for the "no dose" dot.

## Impact

- `lib/features/analytics/bar_chart.dart`: the axis calculation shared by every bar chart and the room it leaves for note dots.
- Tests: new unit tests for the axis calculation; the existing note-dot test must keep passing.
- No data, localization or dependency changes.
