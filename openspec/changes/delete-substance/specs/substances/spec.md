# Spec Delta

## MODIFIED Requirements

### Requirement: Archiving
The edit screen SHALL offer "Archive" with a confirmation. An archived substance SHALL disappear from Home and keep all its intakes, which stay in analytics, until it is restored or deleted from the archive screen.

#### Scenario: Archiving a substance
- **WHEN** the user archives a substance and confirms
- **THEN** its tile disappears from Home
- **AND** its intakes still count in Analytics

## ADDED Requirements

### Requirement: Deleting a substance
The edit screen SHALL offer "Delete". It SHALL ask for confirmation, naming the substance and the number of its entries and stating that this cannot be undone. On confirmation the substance, its doses and all its intakes SHALL be removed, the app SHALL return to Home and show a snackbar naming the deleted substance. Deleted intakes SHALL disappear from "Recent", history and analytics.

#### Scenario: Deleting a test substance
- **WHEN** the user taps "Delete" on the edit screen of "Test" with 12 entries and confirms
- **THEN** Home opens without a "Test" tile
- **AND** none of its 12 entries appear in "Recent" or Analytics

#### Scenario: Cancelling the deletion
- **WHEN** the user taps "Delete" and then "Cancel"
- **THEN** the substance and its entries are unchanged

### Requirement: Archive screen
The archive screen SHALL list archived substances with their icon, name and number of entries. Each SHALL offer "Restore", which puts it back on Home in its previous place in the order, and "Delete", which deletes it as on the edit screen. When the last archived substance is restored or deleted, the screen SHALL return to Home.

#### Scenario: Restoring a substance
- **WHEN** the user taps "Restore" for an archived substance
- **THEN** its tile is back on Home with its history

#### Scenario: Deleting from the archive
- **WHEN** the user taps "Delete" for an archived substance and confirms
- **THEN** it disappears from the archive along with its entries
