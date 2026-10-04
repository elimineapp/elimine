## Why

The ranges are rolling windows: "Year" means the last 12 months, so on 4 October it runs from 1 November and "days with intakes" reads "63 of 338". Nobody thinks in such windows. People think in calendar weeks, months and years, and they want to look back at a particular one ("how was March?"), which rolling windows ending today cannot show.

## What Changes

- **BREAKING (UI)**: "2 wk" is replaced by "Week", a calendar week with one bar per day. "Month" becomes the calendar month (one bar per day of the month) and "Year" the calendar year (one bar per month, January to December). "All years" is unchanged.
- The current week, month or year shows all of its slots. Days or months that have not come yet stay empty.
- A period bar above the chart shows the displayed period ("Sep 28 – Oct 4", "October 2026", "2026") with ‹ and › to step to the previous or next period. A horizontal swipe on the chart does the same. Stepping stops at the current period and at the period of the first intake. Tapping the label returns to the current period.
- Metrics count the elapsed days of the displayed period ("3 of 4" on 4 October). "Busiest weekday" is shown for "Month" only, because in a single week it repeats "Most in a day".
- The substance screen's dose chart gets the same calendar ranges ("Week", "Month", "Year") and the same navigation.
- A "Week starts on" setting (Monday by default, or Sunday) in Settings decides where weeks begin on both charts. It is stored on the device and kept across restarts.

## Capabilities

### New Capabilities

### Modified Capabilities
- `analytics`: ranges become calendar periods; navigation between periods is added; period metrics count elapsed days, and the busiest weekday is shown for "Month" only.
- `substance-chart`: the dose chart's ranges become calendar periods with the same navigation; the intake-count scenario refers to "Week".

The "Week starts on" setting belongs to `analytics`, since it exists only to shape its weeks (the dose chart follows it).

## Impact

- `lib/features/analytics/analytics.dart`: a period model (range plus the period's start) that builds buckets, steps back and forward, and gives the elapsed days. Replaces the rolling skeleton and `rangeQuerySince`.
- `analytics_queries.dart` / `providers.dart`: daily totals bounded by the period (`since` and `until`), and the day of the first intake (overall, or of one substance) to limit stepping back.
- `analytics_screen.dart`, `substance_chart.dart`: the period bar, swipe handling, labels; a shared widget for the period bar.
- `labels.dart`, ARB files: "Week", period titles, axis labels for weeks and calendar months, accessibility labels for the arrows.
- Database: a `settings` key-value table, schema version 3 with a migration step and a migration test (`task db:migrations`).
- Settings screen: a "Week starts on" row with a choice dialog.
- Tests: `analytics_test.dart`, `analytics_screen_test.dart`, `substance_chart_test.dart`.
