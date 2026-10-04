# Spec Delta

## MODIFIED Requirements

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
