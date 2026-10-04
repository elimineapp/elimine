# analytics Specification

## Purpose
A retrospective across all substances over long periods, for comparing substances and spotting relations between them (for example, one substance appearing after a peak of another).

## Requirements

### Requirement: Ranges
Analytics SHALL offer the ranges "2 wk" and "Month" (last 14 and 30 days, one bar per day), "Year" (last 12 months, one bar per month) and "All years" (from the year of the first intake to the current year, one bar per year). Periods without intakes SHALL remain as empty bars.

#### Scenario: All years
- **WHEN** the first intake was in 2024 and the current year is 2026
- **THEN** "All years" shows bars for 2024, 2025 and 2026

### Requirement: Substance filter chips
Analytics SHALL show a chip for every substance with intakes in the selected range, archived ones included and marked "(archived)", ordered by palette color. The chips SHALL act as the legend. Tapping a chip SHALL hide or show that substance in the chart and the metrics without changing any colors.

#### Scenario: Hiding a substance
- **WHEN** the user taps the chip of a visible substance
- **THEN** its segments and its intakes disappear from the chart and the metrics
- **AND** the other substances keep their colors

### Requirement: Stacked intake chart
The chart SHALL count intakes, not doses, because units of different substances cannot be added. Each bar SHALL stack one segment per substance in its color, in palette order. Tapping a bar SHALL pin a tooltip with the period and the number of intakes per substance.

#### Scenario: Two substances on one day
- **WHEN** a day has 2 intakes of one substance and 1 of another
- **THEN** that day's bar is 3 high with segments of 2 and 1

### Requirement: Period metrics
For the selected range and visible substances, Analytics SHALL show: total intakes; days with intakes out of days in the period (e.g. "22 of 30"); the most intakes in a day with its date; the busiest weekday (for "2 wk" and "Month") or the busiest month (for "Year" and "All years"), listing all of them on a tie; and, when more than one substance is visible, each substance's share of intakes in percent. Without intakes in the range it SHALL show "Nothing logged in this period".

#### Scenario: Tie for busiest weekday
- **WHEN** Monday and Thursday have the same, highest number of intakes in the month
- **THEN** the busiest weekday lists both Monday and Thursday

#### Scenario: Shares
- **WHEN** two substances are visible with 6 and 2 intakes
- **THEN** their shares are 75% and 25%
