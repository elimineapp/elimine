# Spec Delta

## Purpose

Exporting all of the user's data into a portable, versioned backup file and importing such files, to restore a device or to bring in history converted from other trackers.

## ADDED Requirements

### Requirement: Export
"Export" on the Settings screen SHALL write all substances (archived ones included) with their doses and intakes into one backup file, saved through the system "Save as" dialog with the default name `elimine-YYYY-MM-DD.json` (today's local date). Intakes the user deleted SHALL NOT be exported. After saving, a snackbar SHALL confirm it; cancelling the dialog SHALL do nothing.

#### Scenario: Exporting
- **WHEN** the user taps "Export" on 4 October 2026 and saves in the dialog
- **THEN** a file named `elimine-2026-10-04.json` with all substances and their intakes is written where the user chose
- **AND** a snackbar confirms the export

#### Scenario: Deleted intakes stay out
- **WHEN** an intake was swiped away before exporting
- **THEN** the backup file does not contain it

### Requirement: Backup file format
The backup file SHALL be UTF-8 JSON with `format` set to `elimine-backup`, an integer `version`, an `exportedAt` time and a list of `substances`. Each substance SHALL have an `id` (UUID), a `name`, and optionally `unit`, `color`, `icon`, `archived`, `doses` (positive numbers) and `intakes`. Each intake SHALL have an `id` (UUID), `takenAt` as ISO 8601 with the UTC offset in effect at that moment, and optionally `amount` (a positive number or null). Missing optional fields and unknown color or icon names SHALL fall back to defaults. The format SHALL be documented for people writing converters.

#### Scenario: Minimal hand-written file
- **WHEN** a file has a substance with only `id` and `name`, and intakes with only `id` and `takenAt`
- **THEN** it imports as a substance without a unit or doses and intakes without a dose

#### Scenario: Local time is kept
- **WHEN** an intake has `takenAt` `2026-09-28T23:30:00+10:00`
- **THEN** after importing it counts on 28 September, wherever the phone is

### Requirement: Import validation
Import SHALL read the whole file and validate it before changing anything. A file that is not a backup, has a newer version than the app supports, or contains an invalid record (a missing or malformed id, name or time, a non-positive dose, a time in the future, an id used twice) SHALL be rejected with a message naming the problem and its place in the file, and nothing SHALL be written.

#### Scenario: Broken record
- **WHEN** the twelfth intake of the first substance has no `takenAt`
- **THEN** the import is rejected with a message pointing at that intake
- **AND** the database is unchanged

#### Scenario: Newer format
- **WHEN** the file's version is higher than the app supports
- **THEN** the import is rejected with a request to update the app

### Requirement: Import adds missing records
A valid file SHALL first be summarized: how many substances and intakes will be added and how many are already present. On confirmation the app SHALL add, in one step, every substance and intake whose id is not in the database, and leave records whose id already exists unchanged. New substances SHALL be placed after the existing ones in file order. Intakes of a substance that already exists SHALL be added to it.

#### Scenario: Restoring onto an empty phone
- **WHEN** a backup with 3 substances and 200 intakes is imported into an empty app
- **THEN** the preview says 3 substances and 200 intakes will be added
- **AND** after confirming, all of them are present with the same times and doses

#### Scenario: Importing the same file again
- **WHEN** the same file is imported a second time
- **THEN** the preview says nothing will be added and all records are already present

#### Scenario: Adding converted history to existing data
- **WHEN** the database has today's intakes and the file holds older intakes of other ids for the same substance id
- **THEN** the older intakes are added to that substance and today's intakes are kept

#### Scenario: Cancelling
- **WHEN** the user cancels on the preview
- **THEN** nothing is written
