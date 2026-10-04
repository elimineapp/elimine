# Spec Delta

## MODIFIED Requirements

### Requirement: Substance screens open above the tabs
The substance screen SHALL open as a sheet over Home that covers the bottom navigation bar, as defined by the substance-screen capability, and system back SHALL close it. The substance edit screen, the new substance screen and the archive screen SHALL open above the bottom navigation bar, with a back action returning to the previous screen.

#### Scenario: Opening a substance
- **WHEN** the user taps a substance tile on Home
- **THEN** the substance screen opens as a sheet over Home, covering the bottom navigation bar
- **AND** going back closes it and returns to Home

#### Scenario: Editing a substance
- **WHEN** the user taps the settings action on the substance screen
- **THEN** the edit screen for that substance opens
- **AND** going back returns to the substance screen

#### Scenario: Opening the archive
- **WHEN** the user taps "Archive (N)" on Home
- **THEN** the archive screen opens without the bottom navigation bar
- **AND** going back returns to Home

#### Scenario: Opening Settings
- **WHEN** the user opens the Settings screen
- **THEN** it opens as a tab, keeping the bottom navigation bar, not above it
