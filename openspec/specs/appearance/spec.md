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

### Requirement: Color palette
Both themes SHALL use near-neutral surfaces: backgrounds, cards, sheets and the navigation bar carry no visible hue. The interface accent SHALL come from the launcher icon's ink color `#1B2638`. Substance colors SHALL stay the most vivid colors on any screen, so that interface elements are not mistaken for a substance.

#### Scenario: Light theme
- **WHEN** the app is in the light theme
- **THEN** backgrounds are a warm off-white and cards a slightly darker warm grey, with no green or other visible tint
- **AND** filled buttons, switches and the progress indicator are dark ink

#### Scenario: Dark theme
- **WHEN** the app is in the dark theme
- **THEN** backgrounds are a dark graphite with at most a faint blue cast, with no green tint
- **AND** filled buttons, switches and the progress indicator are a light steel blue

#### Scenario: Substances stand out
- **WHEN** Home shows substances in the "blue", "aqua" and "green" colors
- **THEN** their tiles and badges are the only saturated colors on the screen, and the "New substance" button and the selected navigation item use the ink accent or neutral tones

#### Scenario: Substance colors unchanged
- **WHEN** the app moves to this palette
- **THEN** every substance keeps the color it had before, in both themes
