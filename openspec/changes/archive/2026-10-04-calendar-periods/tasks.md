## 1. Period model

- [x] 1.1 Add `AnalyticsPeriod` in `analytics.dart` (`current`, `previous`, `next`, `end`, `buckets`, `elapsedDays`, `contains`, first weekday as a parameter); rename `AnalyticsRange.twoWeeks` to `week`; remove `_skeleton` and `rangeQuerySince`
- [x] 1.2 Make `Analytics.build` take a period; `stats().periodDays` = elapsed days of the period ("All years" from the first intake)
- [x] 1.3 Rewrite `analytics_test.dart` for calendar periods; verify with `task test`. Cover a Monday- and a Sunday-first week, a week spanning two years, February in a leap year, the current month with future days empty, 277 elapsed days on 4 October 2026, and stepping back and forward across year boundaries

## 2. Queries

- [x] 2.1 Add `until` to `watchDailyTotals` and to the `dailyTotalsProvider` key; add `watchFirstIntakeDay({substanceId})` with a provider; verify in `database_test.dart` that rows outside the bounds are dropped, that deleted intakes do not count as the first day, and that the first day is per substance

## 3. Week start setting

- [x] 3.1 Add the `settings` table, bump `schemaVersion` to 3 with `from2To3` creating it, run `task db:migrations`, and add data to the generated v2→v3 migration test; verify with `task test`
- [x] 3.2 Add `SettingsService` (`weekStart`, `setWeekStart`) and `weekStartProvider`; verify in `database_test.dart` that Monday is the default and that a saved Sunday is read back
- [x] 3.3 Add the "General" section with a "Week starts on" row and a choice dialog to the Settings screen; ARB strings in en and ru; widget test: Monday by default, choosing Sunday updates the row and is saved

## 4. Period bar and labels

- [x] 4.1 Add `PeriodBar` (`period_bar.dart`): "Previous" / label / "Next", tooltips, disabled states, tap on the label returns to the current period; add `PeriodPages`, a `PageView` with one page per period that follows the finger
- [x] 4.2 Labels in `labels.dart`: period titles (week with years when needed, capitalised month, year) and axis labels (weekdays for a week, the 1st and every 5th day for a month, quarters for a year); ARB strings `rangeWeek`, `previousPeriod`, `nextPeriod` in en and ru, with `rangeTwoWeeks` removed; unit tests for the labels in both languages

## 5. Analytics screen

- [x] 5.1 Wire the current page (`_back`), the period bar, the bounded query, the first-intake limit and the swipe into `AnalyticsScreen`; switching the range resets to the current period; no arrows for "All years"; busiest weekday for "Month" only
- [x] 5.2 Update `analytics_screen_test.dart`: weeks start on the stored setting (Monday by default, Sunday when chosen), the current month shows 31 slots and "x of 4" days, "Previous" shows September with its metrics, "Next" is disabled now, "Previous" is disabled at the first intake's period, a tap on the label returns to now, a fling on the chart steps while a tap still opens a tooltip, there is no busiest weekday for "Week", and switching the range shows the current period

## 6. Substance chart

- [x] 6.1 Use "Week" / "Month" / "Year" calendar periods with the period bar, the swipe and the substance's first intake as the limit in `substance_chart.dart`
- [x] 6.2 Update `substance_chart_test.dart`: the week sum, the current month's daily average, the intake-count mode for "Week", and "Previous" disabled at the substance's first intake

## 7. Check

- [x] 7.1 Manual check on the emulator with imported data: both screens in Russian, switching the week start in Settings, the v2→v3 migration keeping the data, stepping by arrows and by swipe, tooltips still open, labels fit at phone width; then on the phone with the release key (`adb install -r`) after an export
- [x] 7.2 Run `task check` and verify it passes
