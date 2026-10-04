# Spec Delta

## MODIFIED Requirements

### Requirement: Recoverable deletion
Deleting an intake SHALL keep it recoverable through "Undo", and archiving a substance SHALL keep its intakes. Deleting a substance is the one deliberate exception: it is permanent and is only done after an explicit confirmation.

#### Scenario: Archive keeps history
- **WHEN** a substance with intakes is archived
- **THEN** its intakes remain stored

#### Scenario: Deleting a substance asks first
- **WHEN** the user starts deleting a substance
- **THEN** nothing is removed until the user confirms that it cannot be undone

## ADDED Requirements

### Requirement: Deleted substances leave no data
Deleting a substance SHALL erase its name, unit, doses and intakes from the device's storage, so they cannot be recovered from the app's database files.

#### Scenario: Database file after deletion
- **WHEN** a substance named "Zebra-test" with intakes is deleted
- **THEN** the app's database files no longer contain "Zebra-test"
