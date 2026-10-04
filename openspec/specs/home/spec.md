# home Specification

## Purpose
The start screen: one tap from any active substance and an overview of the latest intakes across all substances.

## Requirements

### Requirement: Header
Home SHALL show the app name and the current date in its header, and a settings action that opens the Settings screen.

#### Scenario: Header content
- **WHEN** Home is open
- **THEN** the header shows "Elimine" and today's date in the current locale

#### Scenario: Opening Settings
- **WHEN** the user taps the settings action in the Home header
- **THEN** the Settings screen opens

### Requirement: Substance tiles
Home SHALL show every active (not archived) substance as a tile in a two-column grid, in the user's substance order. A tile SHALL show the substance icon in its color, the name, the unit when there is one, and the last intake as its dose and a relative day ("today", "yesterday", "12 days ago", "2 months ago"), or only the relative day when that intake had no dose. A substance without intakes SHALL show "Not logged yet". Tapping a tile SHALL open the substance screen.

#### Scenario: Tile with history
- **WHEN** a substance's last intake was 250 mg twelve days ago
- **THEN** its tile shows "250 mg · 12 days ago"

#### Scenario: Last intake without a dose
- **WHEN** a substance's last intake had no dose and was yesterday
- **THEN** its tile shows "yesterday"

#### Scenario: Tile without history
- **WHEN** a substance has no intakes
- **THEN** its tile shows "Not logged yet"

#### Scenario: Archived substance
- **WHEN** a substance is archived
- **THEN** it has no tile on Home

### Requirement: New substance tile
The last tile of the grid SHALL be "New", which opens the new substance screen. On first launch, with no substances, it SHALL be the only tile.

#### Scenario: First launch
- **WHEN** the app starts with no data
- **THEN** Home shows only the "New" tile

### Requirement: Recent intakes
Home SHALL list the 10 most recent intakes across all substances under "Recent", newest first, each with its date and time, substance and dose. Swiping an entry away SHALL delete it, as defined by the intake-logging capability.

#### Scenario: Recent list
- **WHEN** intakes of several substances exist
- **THEN** "Recent" shows the latest 10 of them, newest first

### Requirement: Archive entry
When at least one substance is archived, Home SHALL end with an "Archive (N)" row, N being the number of archived substances, that opens the archive screen. Without archived substances the row SHALL NOT be shown.

#### Scenario: Archived substances exist
- **WHEN** two substances are archived
- **THEN** Home ends with "Archive (2)", which opens the archive screen

#### Scenario: Nothing archived
- **WHEN** no substance is archived
- **THEN** Home shows no archive row
