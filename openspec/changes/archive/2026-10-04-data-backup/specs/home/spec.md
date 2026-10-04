# Spec Delta

## MODIFIED Requirements

### Requirement: Header
Home SHALL show the app name and the current date in its header, and a settings action that opens the Settings screen.

#### Scenario: Header content
- **WHEN** Home is open
- **THEN** the header shows "Elimine" and today's date in the current locale

#### Scenario: Opening Settings
- **WHEN** the user taps the settings action in the Home header
- **THEN** the Settings screen opens
