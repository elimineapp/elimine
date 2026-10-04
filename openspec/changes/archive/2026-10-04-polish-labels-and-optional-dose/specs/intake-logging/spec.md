# Spec Delta

## MODIFIED Requirements

### Requirement: Dose selection
Under "Dose", the substance screen SHALL show a chip for each dose of the substance, then a "Custom" chip that asks for a number. At most one dose SHALL be selected; tapping the selected dose chip again SHALL clear the selection, and no selection means the intake has no dose. The dose of the last intake SHALL be preselected, with an extra chip if it is not among the substance's doses, and nothing when it had no dose. With no intakes yet, the first dose SHALL be preselected, or nothing when the substance has no doses. A custom dose SHALL accept a comma or a period as the decimal separator and only positive numbers.

#### Scenario: Last dose preselected
- **WHEN** the last intake of a substance with doses 250 and 500 mg was 500 mg
- **THEN** the 500 mg chip is selected when the screen opens

#### Scenario: Custom last dose
- **WHEN** the last intake was a custom 300 mg
- **THEN** a 300 mg chip is shown next to the substance's doses and selected

#### Scenario: Last intake without a dose
- **WHEN** the last intake of a substance with doses 250 and 500 mg had no dose
- **THEN** no dose chip is selected when the screen opens

#### Scenario: Substance without doses
- **WHEN** a substance has no doses and no intakes
- **THEN** only the "Custom" chip is shown and no dose is selected

#### Scenario: Clearing the dose
- **WHEN** the 250 mg chip is selected and the user taps it
- **THEN** no dose chip is selected

#### Scenario: No "No dose" chip
- **WHEN** the substance screen is open
- **THEN** there is no "No dose" chip

#### Scenario: Entering a custom dose
- **WHEN** the user taps "Custom" and enters "1,5"
- **THEN** a 1.5 dose is selected

### Requirement: Logging
The "Log" button SHALL record an intake with the selected dose, or without a dose when no dose is selected, at the selected time. It SHALL always be enabled. After logging, the device SHALL vibrate, the user SHALL stay on the substance screen, the intake SHALL appear first in the history, a snackbar SHALL offer "Undo", and the time SHALL reset to "Now".

#### Scenario: Logging an intake
- **WHEN** the user taps "Log" with 250 mg selected
- **THEN** a 250 mg intake is recorded at the selected time
- **AND** a snackbar "Logged 250 mg" offers "Undo"

#### Scenario: Logging without a dose
- **WHEN** the user taps "Log" with no dose selected
- **THEN** an intake without a dose is recorded at the selected time
- **AND** a snackbar "Logged" offers "Undo"

#### Scenario: Undo logging
- **WHEN** the user taps "Undo" in that snackbar
- **THEN** the intake disappears from history and analytics

### Requirement: Substance history
The substance screen SHALL list all intakes of the substance, newest first, under "History", or "Nothing logged yet" without intakes. Every intake list SHALL show the dose of each intake that has one, and nothing in its place for an intake without one.

#### Scenario: History order
- **WHEN** a substance has several intakes
- **THEN** its history lists them newest first

#### Scenario: Intake without a dose in a list
- **WHEN** an intake has no dose
- **THEN** its entry in History and in "Recent" shows nothing where the dose would be and never reads "No dose"
