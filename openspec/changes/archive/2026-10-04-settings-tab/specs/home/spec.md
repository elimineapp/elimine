# Spec Delta

## MODIFIED Requirements

### Requirement: Header
Home SHALL show the app name and the current date in its header, and no other actions. Settings is reached through the bottom navigation bar.

#### Scenario: Header content
- **WHEN** Home is open
- **THEN** the header shows "Elimine" and today's date in the current locale

#### Scenario: Opening Settings
- **WHEN** Home is open
- **THEN** its header has no settings action
- **AND** Settings is opened through "Settings" in the bottom navigation bar
