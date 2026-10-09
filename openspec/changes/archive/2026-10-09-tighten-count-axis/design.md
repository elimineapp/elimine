# Design

## Context

Every bar chart picks its axis in `chartAxis` (formerly `_axis`) in `lib/features/analytics/bar_chart.dart`, which returns the top and the gridline interval. Until now the interval was the first of 1, 2, 2.5 or 5 × 10ⁿ at or above a quarter of the tallest bar and the top a whole number of intervals (at least four when counting). `ElimineBarChart` then added one more interval when a bar with a note would have its dot (3 px gap + 6 px dot) stick out of the top. fl_chart offers no rounded or padded maximum of its own: without `maxY` it ends the axis exactly at the tallest bar. Side titles are drawn at every interval and at the maximum; gridlines at every interval except the maximum.

## Goals / Non-Goals

**Goals:**
- A labeled top at or close to the tallest bar (101 → 110, 100 → 100).
- The note dot fits without a whole extra interval.
- Count axes stay whole; small counts get a gridline per intake.

**Non-Goals:**
- Round gridline values (50, 100) inside the chart: the halfway line takes whatever value half the top is.
- Changing the chart's height, colors or label style.

## Decisions

**Top: two significant digits, at or above the tallest bar.** With `unit = 10^(digits − 2)` (e.g. 10 for 101, 1 for 51, 0.01 for 0.3), the top is the first multiple of `unit` at or above the tallest bar: 101 → 110, 100 → 100, 99 → 100, 250 → 250. A bar that reaches the top is fine: the top has no gridline drawn over it, and the bar ends exactly at the labeled value. The only reason for a gap would be the note dot, which gets its own room (below). The gap is 0–10% of the top.

**Counts: whole; small ones by 1, the rest even.** When counting, `unit` is at least 1. A top of 5 or less gets an interval of 1, so every whole number has a gridline and a label: 3 intakes give 0–1–2–3. A single intake gets 0–1: like any tallest bar it reaches the top, and the axis labels tell one intake from many. Above 5, while `unit` is 1, the top is rounded up to an even number so the halfway value is whole (51 → 52, halfway 26); above 100 every multiple of `unit` is already even. The earlier floor of 4 is dropped: it existed so one or two intakes would not touch the top, and with the even rule it pushed 2 intakes to 0–2–4, half empty. Six labels (top 5) on the 176 dp plot are about 35 dp apart, enough for `labelSmall`.

**One halfway gridline otherwise.** The interval is `top / 2`, so fl_chart draws labels at 0, half and the top, and one gridline at half. The top value is labeled because it is a multiple of the interval. Two intervals keep labels far apart even on the 200 dp chart.

**Room for the note dot before rounding.** `ElimineBarChart.build` passes `chartAxis` the larger of the tallest bar and, for bars with a note, `total × h / (h − 9)` (h = plot height): the value at which the dot's top would touch the axis top. Rounding up from there always leaves the dot inside, so the "add an interval" branch goes away. The dot's size in chart units is still derived from the final top.

**Empty periods.** No bars: counts as if the tallest bar were 1 (top 1, interval 1); doses top 1, interval 0.5.

**Floating point.** Divisions like `0.28 / 0.01` give 28.000…4; the multiple count uses `ceil(max / unit − ε)` with a small ε so such a value is not pushed to the next multiple, and the result is computed as `k × unit` rounded to the unit's decimals so labels do not show `0.30000000000000004`.

Alternatives considered: top on the next round step (101 → 150, too empty); finer round steps up to six intervals (101 → 120, gridline count varies between pages); a pixel gap above the tallest bar with an unlabeled top (rejected: the top should carry a number); round gridlines plus a labeled top (labels collide when the top is just above a round line).

**Test `chartAxis` directly.** It is public and `@visibleForTesting`, so each case is one expectation without pumping a chart.

## Risks / Trade-offs

- [Halfway labels can be odd numbers such as 26 or 55] → Accepted: the top is what readers compare against, and the tooltip gives exact values.
- [The top changes in small steps between neighbouring pages (110 vs 120)] → Unchanged in kind: each page has always scaled to its own bars.
- [The tallest bar often reaches the top (100 → 100)] → Intended: no gridline is drawn at the top, and the bar ends at the labeled value.
