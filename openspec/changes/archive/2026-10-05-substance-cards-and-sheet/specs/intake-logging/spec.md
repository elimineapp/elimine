# Spec Delta

## MODIFIED Requirements

### Requirement: Logging
The "Log" button SHALL record an intake with the selected dose, or without a dose when no dose is selected, at the selected time. It SHALL always be enabled. After logging, the device SHALL vibrate, the time SHALL reset to "Now" and a snackbar SHALL offer "Undo". When the substance screen is collapsed, it SHALL close and the snackbar SHALL appear on Home. When it is expanded, the user SHALL stay on it and the intake SHALL appear first in the history.

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

#### Scenario: Logging from the collapsed screen
- **WHEN** the substance screen is collapsed and the user taps "Log"
- **THEN** the substance screen closes
- **AND** Home shows the snackbar and the substance's tile shows the new intake

#### Scenario: Logging from the expanded screen
- **WHEN** the substance screen is expanded and the user taps "Log"
- **THEN** the substance screen stays open and expanded
- **AND** the intake appears first in its history and the snackbar shows on the substance screen
