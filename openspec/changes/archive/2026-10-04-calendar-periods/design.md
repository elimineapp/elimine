## Context

- `analytics.dart` builds buckets from a rolling skeleton that ends today (`_skeleton`), and `rangeQuerySince` gives the lower bound for the daily-totals query. Both are keyed by `AnalyticsRange { twoWeeks, month, year, allYears }`.
- Buckets are UTC midnights used as plain calendar dates, and days come from SQL as local `YYYY-MM-DD` at the moment of intake. This stays as it is.
- `AnalyticsScreen` and `SubstanceChart` each keep `_range` in widget state and use the same `Analytics.build` and `ElimineBarChart`. The chart handles taps itself through fl_chart (`handleBuiltInTouches: false`, tap-up callback).

## Goals / Non-Goals

**Goals:**
- One period model shared by both screens: it builds the slots, steps back and forward, and counts elapsed days.
- Queries bounded by the displayed period, so a past month reads only its own rows.

**Non-Goals:**
- Drilling down from a bar (tapping a month to open it) and custom date ranges.
- Remembering the displayed period across app restarts.

## Decisions

### A period value instead of a rolling skeleton
`AnalyticsPeriod(range, start)` is an immutable value. `start` is the UTC date of the first day of the week, the 1st of the month, or 1 January:
- `AnalyticsPeriod.current(range, today, {firstWeekday})` returns the period that contains today;
- `previous` / `next` step by 7 days, one month or one year;
- `end` is exclusive;
- `buckets` yields 7 days, 28–31 days, or 12 months;
- `elapsedDays(today)` gives the days from `start` through today, capped at the period's length (0 for a future period, which cannot be reached).

"All years" stays a special case. Its period runs from the year of the first intake through the current year, and it has no `previous`/`next`. `Analytics.build(period, rows, today:, visible:)` takes the period in place of a range, and `stats().periodDays` becomes `period.elapsedDays(today)`, from the first intake for "All years" as today. `rangeQuerySince` and `_skeleton` are removed, and `AnalyticsRange.twoWeeks` becomes `week`.

Alternatives: keep a range plus an offset ("3 months back"). An offset changes meaning when the date rolls over at midnight. An explicit start date does not.

### Bounded query and the first intake
`watchDailyTotals` gets `until` next to `since`. The provider key is `(since, until, substanceId)` at day precision, with a day of margin on each side because the bound is compared against the UTC instant. Rows are then trimmed by their local `day`, as now.

A new `watchFirstIntakeDay({substanceId})` returns `MIN(day)` over intakes that are not deleted, as a `YYYY-MM-DD` string or null. It feeds the "Previous" limit and the "All years" start. A stream keeps the limit right after logging or importing.

### First day of the week: a stored setting
The week starts on a day chosen in Settings: Monday (default) or Sunday. It is kept in a new Drift table `settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)`, with schema version 3. Its step only creates the table: `from2To3: (m, schema) => m.createTable(schema.settings)`. Snapshots, steps and the migration test come from `task db:migrations`. Key `weekStart`, values `monday` / `sunday`; a missing row means Monday.

Why Drift and not `shared_preferences`: there is no new plugin and no second storage location. The value is also read as a stream, so the charts update as soon as it changes. The table is generic, so later settings need no new migration. Backups do not carry settings: the backup format describes records, and a setting is a device preference.

`SettingsService.setWeekStart` writes the row, and `weekStartProvider` (a `StreamProvider<int>` with `DateTime.weekday` values, `DateTime.monday` until loaded) feeds both charts. The Settings screen gets a "Week starts on" `ListTile` in a "General" section above "Backup". Its subtitle names the day; tapping opens a dialog with two radio options and saves on selection.

Alternatives: follow the locale's first day of the week (`MaterialLocalizations.firstDayOfWeekIndex`). Rejected by the maintainer: Monday is the expected default regardless of language.

### Period bar and swipe
`PeriodBar` (in `features/analytics/period_bar.dart`) is a row with a "Previous" `IconButton` (chevron), a centered `TextButton` with the label, and a "Next" `IconButton`. The icon buttons have tooltips, which also give TalkBack names. Disabled arrows are null-callback buttons. Both screens put it between the range buttons and the chart.

Swipe: the chart sits in a `PageView` (`PeriodPages`) with one page per period. Page 0 is the current period, and higher pages are older (`reverse: true`, so they lie to the left). The page count comes from `pagesBackTo(firstDay)`. While dragging, the chart follows the finger and the neighbouring period slides in. The arrows call `animateToPage`, so they slide the same way, and the label and the range buttons jump to page 0. Each page watches its own period's rows. The screen keeps `_back` (pages back from now) from `onPageChanged` and computes the period bar, the title and the metrics for that page. Taps still reach fl_chart: the page scroll only claims horizontal drags. A widget test covers both a tap and a fling. A new range gets a new `PageView` key, so it starts on its current period.

Alternative: a fling detector that swaps the chart, with a slide transition afterwards. Simpler, but the maintainer wanted the chart to follow the finger.

Labels:
- Week: `MMMd – MMMd`, with years added (`yMMMd`) when the week is not in the current year or spans two years.
- Month: `yMMMM`, capitalised, e.g. "Октябрь 2026 г." / "October 2026".
- Year: `y`.

Axis labels:
- Week: every day, abbreviated weekday (`E`).
- Month: the 1st and every 5th day.
- Year: January, April, July, October (`LLL`).

### State
Each screen keeps `_range` and `_back`. Selecting a range returns to its current period. The filter chips' hidden set is kept while stepping. Analytics state survives tab switches as it does now.

## Risks / Trade-offs

- [A swipe on the chart could be taken as a tap or lost to fl_chart] → the widget test above and a check on a device.
- [Neighbouring pages query their own periods] → the queries are small and bounded, and a `PageView` builds only the visible pages.
- [A schema migration on a database with real data] → a step that only creates a table, a generated migration test from v2 with data, and a backup (export) before installing on the phone.
- [Until a period is past, the 1 January – today day count includes days before the user started tracking] → this is what "of the days that have begun" means. "All years" already starts at the first intake.

## Migration Plan

Schema 2 → 3 adds the empty `settings` table. Existing data is untouched. The UI change ships in the next release, and the changelog lists it as a feature.
