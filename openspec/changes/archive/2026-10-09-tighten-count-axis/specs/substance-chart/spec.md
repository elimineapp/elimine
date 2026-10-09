# Spec Delta

## ADDED Requirements

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
