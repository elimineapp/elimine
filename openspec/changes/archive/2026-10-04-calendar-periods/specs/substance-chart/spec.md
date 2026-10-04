## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Intake count when no dose is known
When the displayed period has intakes of the substance but none of them has a dose, the chart SHALL count intakes per day (or per month for "Year") instead of summing doses, titled "Intakes", with whole-number axis steps.

#### Scenario: History without doses
- **WHEN** a substance's intakes this week all have no dose and "Week" is selected
- **THEN** the chart shows the number of intakes per day under the title "Intakes"

#### Scenario: A dose appears
- **WHEN** one intake in the period has a dose
- **THEN** the chart sums doses and marks the other days with dots

## REMOVED Requirements

### Requirement: Dose chart ranges
**Reason**: The rolling ranges "2 wk", "Month" (last 30 days) and "Year" (last 12 months) are replaced by calendar periods.
**Migration**: See "Dose chart periods" and "Dose chart navigation".
