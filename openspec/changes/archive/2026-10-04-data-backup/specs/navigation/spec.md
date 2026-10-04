# Spec Delta

## MODIFIED Requirements

### Requirement: Substance screens open above the tabs
The substance screen, the substance edit screen, the new substance screen, the archive screen and the Settings screen SHALL open above the bottom navigation bar, with a back action returning to the previous screen.

#### Scenario: Opening a substance
- **WHEN** the user taps a substance tile on Home
- **THEN** the substance screen opens without the bottom navigation bar
- **AND** going back returns to Home

#### Scenario: Editing a substance
- **WHEN** the user taps the settings action on the substance screen
- **THEN** the edit screen for that substance opens

#### Scenario: Opening the archive
- **WHEN** the user taps "Archive (N)" on Home
- **THEN** the archive screen opens without the bottom navigation bar
- **AND** going back returns to Home

#### Scenario: Opening Settings
- **WHEN** the user taps the settings action in the Home header
- **THEN** the Settings screen opens without the bottom navigation bar
- **AND** going back returns to Home
