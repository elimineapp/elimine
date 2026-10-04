## MODIFIED Requirements

### Requirement: Ranges
Analytics SHALL offer the ranges "Week" (a calendar week, one bar per day), "Month" (a calendar month, one bar per day of the month), "Year" (a calendar year, one bar per month from January to December) and "All years" (from the year of the first intake to the current year, one bar per year). The week SHALL start on the day chosen in Settings (Monday by default). Analytics SHALL open on the current period of the selected range. Periods without intakes, including days or months that have not come yet, SHALL remain as empty bars.

#### Scenario: All years
- **WHEN** the first intake was in 2024 and the current year is 2026
- **THEN** "All years" shows bars for 2024, 2025 and 2026

#### Scenario: Current month
- **WHEN** "Month" is selected and today is 4 October
- **THEN** the chart shows 31 bars for 1 to 31 October, and 5 to 31 October are empty

#### Scenario: Current year
- **WHEN** "Year" is selected and today is 4 October 2026
- **THEN** the chart shows 12 bars for January to December 2026, and November and December are empty

#### Scenario: Default week
- **WHEN** the week start was never changed, "Week" is selected and today is Sunday 4 October
- **THEN** the chart shows Monday 28 September to Sunday 4 October

### Requirement: Period metrics
For the displayed period and visible substances, Analytics SHALL show: total intakes; days with intakes out of the days of the period that have already begun (e.g. "3 of 4" on the 4th of a month, "22 of 30" for a past month); the most intakes in a day with its date; the busiest weekday (for "Month") or the busiest month (for "Year" and "All years"), listing all of them on a tie; and, when more than one substance is visible, each substance's share of intakes in percent. Without intakes in the period it SHALL show "Nothing logged in this period".

#### Scenario: Tie for busiest weekday
- **WHEN** Monday and Thursday have the same, highest number of intakes in the month
- **THEN** the busiest weekday lists both Monday and Thursday

#### Scenario: Shares
- **WHEN** two substances are visible with 6 and 2 intakes
- **THEN** their shares are 75% and 25%

#### Scenario: Days of the current year
- **WHEN** "Year" is selected, today is 4 October 2026 and 63 days this year had intakes
- **THEN** days with intakes reads "63 of 277"

#### Scenario: No busiest weekday for a week
- **WHEN** "Week" is selected
- **THEN** no busiest weekday is shown

## ADDED Requirements

### Requirement: First day of the week
The Settings screen SHALL have a "Week starts on" row showing the chosen day, Monday by default. Tapping it SHALL offer Monday and Sunday; the choice SHALL apply at once to the "Week" range on Analytics and on the dose chart, and SHALL be kept on the device across restarts. It SHALL NOT be part of backup files.

#### Scenario: Sunday-first weeks
- **WHEN** the user chooses Sunday and "Week" is selected on Sunday 4 October
- **THEN** the chart shows Sunday 4 October to Saturday 10 October

#### Scenario: Kept after restart
- **WHEN** the user chose Sunday and restarts the app
- **THEN** "Week starts on" still shows Sunday

### Requirement: Period navigation
Above the chart, Analytics SHALL show the displayed period, e.g. "Sep 28 – Oct 4", "October 2026" or "2026", between a "Previous" and a "Next" arrow. The arrows, and a horizontal swipe on the chart, SHALL show the previous or next period of the same range; while swiping, the chart SHALL follow the finger with the neighbouring period sliding in, and the arrows SHALL slide the same way. "Next" SHALL be disabled on the current period. "Previous" SHALL be disabled on the period that contains the first intake, or on the current period when there are no intakes. Tapping the period label SHALL return to the current period. Switching the range SHALL show the current period of the new range. "All years" SHALL show no arrows.

#### Scenario: Previous month
- **WHEN** "Month" shows October 2026 and the user taps "Previous"
- **THEN** the chart and the metrics show September 2026

#### Scenario: Swipe
- **WHEN** the chart shows September 2026 and the user swipes it from right to left
- **THEN** October 2026 is shown

#### Scenario: Nothing after the current period
- **WHEN** the current month is shown
- **THEN** "Next" is disabled

#### Scenario: Nothing before the first intake
- **WHEN** the first intake was in March 2025 and "Month" shows March 2025
- **THEN** "Previous" is disabled

#### Scenario: Back to now
- **WHEN** "Year" shows 2024 and the user taps the period label
- **THEN** the current year is shown
