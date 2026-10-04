# Spec Delta

## MODIFIED Requirements

### Requirement: Bottom navigation
The app SHALL show a bottom navigation bar with three destinations, in this order: "Settings", "Home" and "Analytics". The app SHALL open on "Home". Each destination SHALL keep its own state (such as scroll position and selected range) while the user switches between them.

#### Scenario: Switching tabs keeps state
- **WHEN** the user selects the "Year" range on Analytics, switches to Home and back
- **THEN** Analytics still shows the "Year" range

#### Scenario: Destination order
- **WHEN** the app is open on any tab
- **THEN** the bottom navigation bar shows "Settings", "Home" and "Analytics", from left to right

#### Scenario: App opens on Home
- **WHEN** the app starts
- **THEN** Home is open and its destination, the middle one, is selected

#### Scenario: Settings tab
- **WHEN** the user taps "Settings" in the bottom navigation bar
- **THEN** the Settings screen opens with the bottom navigation bar still shown
- **AND** the Settings screen has no back action

### Requirement: Substance screens open above the tabs
The substance screen, the substance edit screen, the new substance screen and the archive screen SHALL open above the bottom navigation bar, with a back action returning to the previous screen.

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
- **WHEN** the user opens the Settings screen
- **THEN** it opens as a tab, keeping the bottom navigation bar, not above it
