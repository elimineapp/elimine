# Spec Delta

## MODIFIED Requirements

### Requirement: Dose chart ranges
The substance screen SHALL show a bar chart of doses in the substance's unit with ranges "2 wk" and "Month" (last 14 and 30 days, one bar per day, the sum of doses that day) and "Year" (last 12 months, one bar per month, the daily average). The daily average SHALL divide the month's sum by the days in the month, or by the days elapsed so far for the current month. Intakes without a dose SHALL NOT add to the sums. The title SHALL name the measure and the unit, e.g. "Per day, mg" or "Daily average, mg", and only the measure when the substance has no unit.

#### Scenario: Two weeks
- **WHEN** "2 wk" is selected and 500 mg were logged today in two intakes
- **THEN** today's bar is 500

#### Scenario: Current month average
- **WHEN** "Year" is selected, today is the 10th and 100 mg were logged this month
- **THEN** this month's bar is 10

#### Scenario: Substance without a unit
- **WHEN** the substance has no unit and "2 wk" is selected
- **THEN** the chart title reads "Per day"

### Requirement: Tooltip on tap
Tapping a bar SHALL pin a tooltip with its date or month, its value with the unit and, when the period had intakes without a dose, their number; tapping it again or elsewhere SHALL clear it.

#### Scenario: Tapping a bar
- **WHEN** the user taps a day bar with 250 mg
- **THEN** a tooltip shows that date and "250 mg"

#### Scenario: Tapping a bar with intakes without a dose
- **WHEN** the user taps a day with a 250 mg intake and one intake without a dose
- **THEN** the tooltip shows that date, "250 mg" and "1 without dose"

## ADDED Requirements

### Requirement: Intakes without a dose on the dose chart
On the dose chart, every day (or month, for "Year") that had at least one intake without a dose SHALL show a dot just above its bar, or just above the baseline when it has no dose. Tapping that day SHALL show its tooltip like any bar.

#### Scenario: Mixed day
- **WHEN** a day had a 250 mg intake and an intake without a dose
- **THEN** its bar is 250 with a dot above it

#### Scenario: Day with only intakes without a dose
- **WHEN** a day had only intakes without a dose
- **THEN** it has no bar and a dot just above the baseline

### Requirement: Intake count when no dose is known
When the selected range has intakes of the substance but none of them has a dose, the chart SHALL count intakes per day (or per month for "Year") instead of summing doses, titled "Intakes", with whole-number axis steps.

#### Scenario: History without doses
- **WHEN** a substance's intakes in the last 14 days all have no dose and "2 wk" is selected
- **THEN** the chart shows the number of intakes per day under the title "Intakes"

#### Scenario: A dose appears
- **WHEN** one intake in the range has a dose
- **THEN** the chart sums doses and marks the other days with dots
