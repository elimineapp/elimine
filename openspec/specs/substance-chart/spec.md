# substance-chart Specification

## Purpose
A dose chart on the substance screen showing how much of one substance was taken over time.

## Requirements

### Requirement: Dose chart periods
The substance screen SHALL show a bar chart of doses in the substance's unit with the calendar ranges "Week" and "Month" (one bar per day, the sum of doses that day) and "Year" (one bar per month from January to December, the daily average), opening on the current period. The daily average SHALL divide the month's sum by the days in the month, or by the days elapsed so far for the current month. Days or months that have not come yet SHALL stay empty. Intakes without a dose SHALL NOT add to the sums. The title SHALL name the measure and the unit, e.g. "Per day, mg" or "Daily average, mg", and only the measure when the substance has no unit.

#### Scenario: Week
- **WHEN** "Week" is selected and 500 mg were logged today in two intakes
- **THEN** today's bar is 500

#### Scenario: Current month average
- **WHEN** "Year" is selected, today is the 10th and 100 mg were logged this month
- **THEN** this month's bar is 10

#### Scenario: Substance without a unit
- **WHEN** the substance has no unit and "Week" is selected
- **THEN** the chart title reads "Per day"

### Requirement: Dose chart navigation
The dose chart SHALL have the same period bar as Analytics: the displayed period between "Previous" and "Next" arrows, a horizontal swipe on the chart that follows the finger to step, "Next" disabled on the current period, "Previous" disabled on the period that contains the substance's first intake, and a tap on the label returning to the current period.

#### Scenario: Previous week
- **WHEN** "Week" shows the current week and the user taps "Previous"
- **THEN** the chart shows the week before

#### Scenario: First intake of the substance
- **WHEN** the substance's first intake was in June 2026 and "Month" shows June 2026
- **THEN** "Previous" is disabled

### Requirement: Empty periods stay visible
Bars SHALL start at a zero baseline, and periods without intakes SHALL remain as empty slots instead of being skipped or interpolated.

#### Scenario: Gap
- **WHEN** nothing was logged on some days of the range
- **THEN** those days appear as empty slots

### Requirement: Tooltip on tap
Tapping a bar SHALL pin a tooltip with its date or month, its value with the unit and, when the period had intakes without a dose, its number of intakes; tapping it again or elsewhere SHALL clear it. The tooltip SHALL NOT mention intakes "without dose".

#### Scenario: Tapping a bar
- **WHEN** the user taps a day bar with 250 mg
- **THEN** a tooltip shows that date and "250 mg"

#### Scenario: Tapping a bar with intakes without a dose
- **WHEN** the user taps a day with a 250 mg intake and one intake without a dose
- **THEN** the tooltip shows that date, "250 mg" and "2 intakes"

#### Scenario: Tapping a day with only intakes without a dose
- **WHEN** the user taps the dot of a day with one intake, which had no dose
- **THEN** the tooltip shows that date and "1 intake"

### Requirement: Intakes without a dose on the dose chart
On the dose chart, every day (or month, for "Year") that had at least one intake without a dose SHALL show a dot just above its bar, or just above the baseline when it has no dose. Tapping that day SHALL show its tooltip like any bar.

#### Scenario: Mixed day
- **WHEN** a day had a 250 mg intake and an intake without a dose
- **THEN** its bar is 250 with a dot above it

#### Scenario: Day with only intakes without a dose
- **WHEN** a day had only intakes without a dose
- **THEN** it has no bar and a dot just above the baseline

### Requirement: Intake count when no dose is known
When the displayed period has intakes of the substance but none of them has a dose, the chart SHALL count intakes per day (or per month for "Year") instead of summing doses, titled "Intakes", with whole-number axis steps.

#### Scenario: History without doses
- **WHEN** a substance's intakes this week all have no dose and "Week" is selected
- **THEN** the chart shows the number of intakes per day under the title "Intakes"

#### Scenario: A dose appears
- **WHEN** one intake in the period has a dose
- **THEN** the chart sums doses and marks the other days with dots

### Requirement: Value axis ends near the tallest bar
The chart's value axis SHALL end at the smallest value at or above the tallest bar that has at most two significant digits, or above its dot for intakes without a dose when it has one, and SHALL be labeled at 0, halfway and the top. When the chart counts intakes, the axis SHALL follow the Analytics intake chart: whole numbers, every whole number labeled up to a top of 5, and an even top up to 100.

#### Scenario: Dose axis
- **WHEN** the tallest bar of the displayed week is 250 mg
- **THEN** the value axis is labeled 0, 125 and 250 and the tallest bar reaches the top

#### Scenario: Dot above the tallest bar
- **WHEN** the tallest bar of the displayed week is 250 mg and that day also had an intake without a dose
- **THEN** the dot above that bar fits under the top of the axis, which still has at most two significant digits

#### Scenario: Count axis
- **WHEN** the chart counts intakes and the busiest month of the displayed year has 9 intakes
- **THEN** the value axis is labeled 0, 5 and 10

#### Scenario: Few counted intakes
- **WHEN** the chart counts intakes and the busiest day of the displayed week has 1 intake
- **THEN** the value axis is labeled 0 and 1
