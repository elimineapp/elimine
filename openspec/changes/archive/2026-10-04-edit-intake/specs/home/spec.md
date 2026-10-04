# Spec Delta

## MODIFIED Requirements

### Requirement: Recent intakes
Home SHALL list the 10 most recent intakes across all substances under "Recent", newest first, each with its date and time, substance and dose. Tapping an entry SHALL open its edit sheet and swiping it away SHALL delete it, as defined by the intake-logging capability.

#### Scenario: Recent list
- **WHEN** intakes of several substances exist
- **THEN** "Recent" shows the latest 10 of them, newest first

#### Scenario: Editing from Recent
- **WHEN** the user taps an entry under "Recent"
- **THEN** the "Edit entry" sheet for that intake opens on Home
