# Spec Delta

## ADDED Requirements

### Requirement: Intake chart axis
The chart's value axis SHALL end at the smallest whole number at or above the tallest bar of the displayed period that has at most two significant digits. Up to a top of 5 the axis SHALL be labeled at every whole number. Above that, a top of at most 100 SHALL be even, and the axis SHALL be labeled at 0, halfway and the top.

#### Scenario: Axis ends near the tallest bar
- **WHEN** "Year" is selected and the busiest month of the displayed year has 101 intakes
- **THEN** the value axis is labeled 0, 55 and 110

#### Scenario: Axis below 100
- **WHEN** the tallest bar of the displayed period has 51 intakes
- **THEN** the value axis is labeled 0, 26 and 52

#### Scenario: Few intakes
- **WHEN** the tallest bar of the displayed period has 3 intakes
- **THEN** the value axis is labeled 0, 1, 2 and 3 and the tallest bar reaches the top

#### Scenario: A single intake
- **WHEN** the tallest bar of the displayed period has 1 intake
- **THEN** the value axis is labeled 0 and 1 and the bar reaches the top

#### Scenario: Empty period
- **WHEN** the displayed period has no intakes
- **THEN** the value axis is labeled 0 and 1
