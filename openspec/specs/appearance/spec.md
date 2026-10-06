# appearance Specification

## Purpose
How the app looks as a whole, independent of any one screen: currently, whether it uses the light or the dark theme.

## Requirements

### Requirement: Theme choice
The "General" section of the Settings screen SHALL have a "Theme" row showing the current choice, "System" by default. Tapping it SHALL offer "System", "Light" and "Dark". "System" SHALL follow the device's light or dark mode, including when it changes while the app is open. "Light" and "Dark" SHALL use that theme whatever the device mode is. The choice SHALL apply at once to every screen, without a restart.

#### Scenario: System by default
- **WHEN** the user never chose a theme and the device is in dark mode
- **THEN** the app uses the dark theme
- **AND** the "Theme" row shows "System"

#### Scenario: Light on a dark device
- **WHEN** the device is in dark mode and the user chooses "Light"
- **THEN** the app switches to the light theme at once, substance colors included

#### Scenario: Device mode changes
- **WHEN** the choice is "Dark" and the device switches to light mode
- **THEN** the app stays dark

### Requirement: Theme choice is kept
The theme choice SHALL be kept on the device across restarts, and the app SHALL draw its first frame in the chosen theme. It SHALL NOT be part of backup files.

#### Scenario: Kept after restart
- **WHEN** the user chose "Light" on a dark device and restarts the app
- **THEN** the app's first frame is light, without first showing the dark theme
- **AND** the "Theme" row still shows "Light"

#### Scenario: Not in backups
- **WHEN** the user chose "Dark" and exports a backup
- **THEN** the backup file does not contain the theme choice
