# local-data Specification

## Purpose
Where the user's data lives and who can reach it: only this device, with nothing sent anywhere.

## Requirements

### Requirement: Data stays on the device
The app SHALL store all data locally on the device and SHALL NOT use a server, accounts, sync or any network access.

#### Scenario: Offline use
- **WHEN** the device has no network connection
- **THEN** every feature of the app works

### Requirement: No cloud backup
The app SHALL opt out of the platform's automatic cloud backup and device-to-device transfer, so its data never leaves the device without an explicit user action.

#### Scenario: System backup
- **WHEN** the operating system runs its automatic backup
- **THEN** no app data is included

### Requirement: Recoverable deletion
Deleting an intake SHALL keep it recoverable through "Undo", and archiving a substance SHALL keep its intakes.

#### Scenario: Archive keeps history
- **WHEN** a substance with intakes is archived
- **THEN** its intakes remain stored
