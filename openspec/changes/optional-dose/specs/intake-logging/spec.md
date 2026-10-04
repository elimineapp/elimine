# Spec Delta

## MODIFIED Requirements

### Requirement: Dose selection
Under "Dose", the substance screen SHALL show a "No dose" chip first, then a chip for each dose of the substance, then a "Custom" chip that asks for a number. Exactly one option SHALL be selected at any time. The dose of the last intake SHALL be preselected: "No dose" if it had none, and an extra chip if its dose is not among the substance's doses. With no intakes yet, the first dose SHALL be preselected, or "No dose" when the substance has no doses. A custom dose SHALL accept a comma or a period as the decimal separator and only positive numbers.

#### Scenario: Last dose preselected
- **WHEN** the last intake of a substance with doses 250 and 500 mg was 500 mg
- **THEN** the 500 mg chip is selected when the screen opens

#### Scenario: Custom last dose
- **WHEN** the last intake was a custom 300 mg
- **THEN** a 300 mg chip is shown next to the substance's doses and selected

#### Scenario: Last intake without a dose
- **WHEN** the last intake of a substance with doses 250 and 500 mg had no dose
- **THEN** the "No dose" chip is selected when the screen opens

#### Scenario: Substance without doses
- **WHEN** a substance has no doses and no intakes
- **THEN** the "No dose" chip is selected

#### Scenario: Entering a custom dose
- **WHEN** the user taps "Custom" and enters "1,5"
- **THEN** a 1.5 dose is selected

### Requirement: Logging
The "Log" button SHALL record an intake with the selected dose, or without a dose when "No dose" is selected, at the selected time. It SHALL always be enabled. After logging, the device SHALL vibrate, the user SHALL stay on the substance screen, the intake SHALL appear first in the history, a snackbar SHALL offer "Undo", and the time SHALL reset to "Now".

#### Scenario: Logging an intake
- **WHEN** the user taps "Log" with 250 mg selected
- **THEN** a 250 mg intake is recorded at the selected time
- **AND** a snackbar "Logged 250 mg" offers "Undo"

#### Scenario: Logging without a dose
- **WHEN** the user taps "Log" with "No dose" selected
- **THEN** an intake without a dose is recorded at the selected time
- **AND** a snackbar "Logged" offers "Undo"

#### Scenario: Undo logging
- **WHEN** the user taps "Undo" in that snackbar
- **THEN** the intake disappears from history and analytics

### Requirement: Substance history
The substance screen SHALL list all intakes of the substance, newest first, under "History", or "Nothing logged yet" without intakes. Every intake list SHALL show the dose of each intake, or "No dose" for an intake without one.

#### Scenario: History order
- **WHEN** a substance has several intakes
- **THEN** its history lists them newest first

#### Scenario: Intake without a dose in a list
- **WHEN** an intake has no dose
- **THEN** its entry in History and in "Recent" reads "No dose" where the dose would be
