# navigation Specification

## Purpose
How the user moves between the app's screens, keeping the daily path from launch to a logged intake short.

## Requirements

### Requirement: Bottom navigation
The app SHALL show a bottom navigation bar with two destinations, "Home" and "Analytics". Each destination SHALL keep its own state (such as scroll position and selected range) while the user switches between them.

#### Scenario: Switching tabs keeps state
- **WHEN** the user selects the "Year" range on Analytics, switches to Home and back
- **THEN** Analytics still shows the "Year" range

### Requirement: Substance screens open above the tabs
The substance screen, the substance edit screen and the new substance screen SHALL open above the bottom navigation bar, with a back action returning to the previous screen.

#### Scenario: Opening a substance
- **WHEN** the user taps a substance tile on Home
- **THEN** the substance screen opens without the bottom navigation bar
- **AND** going back returns to Home

#### Scenario: Editing a substance
- **WHEN** the user taps the settings action on the substance screen
- **THEN** the edit screen for that substance opens
