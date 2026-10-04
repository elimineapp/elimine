# substance-chart Specification

## Purpose
A dose chart on the substance screen showing how much of one substance was taken over time.

## Requirements

### Requirement: Dose chart ranges
The substance screen SHALL show a bar chart of doses in the substance's unit with ranges "2 wk" and "Month" (last 14 and 30 days, one bar per day, the sum of doses that day) and "Year" (last 12 months, one bar per month, the daily average). The daily average SHALL divide the month's sum by the days in the month, or by the days elapsed so far for the current month. The axis title SHALL name the measure and unit, e.g. "Per day, mg" or "Daily average, mg".

#### Scenario: Two weeks
- **WHEN** "2 wk" is selected and 500 mg were logged today in two intakes
- **THEN** today's bar is 500

#### Scenario: Current month average
- **WHEN** "Year" is selected, today is the 10th and 100 mg were logged this month
- **THEN** this month's bar is 10

### Requirement: Empty periods stay visible
Bars SHALL start at a zero baseline, and periods without intakes SHALL remain as empty slots instead of being skipped or interpolated.

#### Scenario: Gap
- **WHEN** nothing was logged on some days of the range
- **THEN** those days appear as empty slots

### Requirement: Tooltip on tap
Tapping a bar SHALL pin a tooltip with its date or month and its value with the unit; tapping it again or elsewhere SHALL clear it.

#### Scenario: Tapping a bar
- **WHEN** the user taps a day bar with 250 mg
- **THEN** a tooltip shows that date and "250 mg"
