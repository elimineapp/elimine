# Spec Delta

## MODIFIED Requirements

### Requirement: Recoverable deletion
Deleting an intake SHALL keep it recoverable through "Undo", and archiving a substance SHALL keep its intakes. Deleting a substance and erasing all data after a forgotten PIN are the deliberate exceptions: they are permanent and are only done after an explicit confirmation.

#### Scenario: Archive keeps history
- **WHEN** a substance with intakes is archived
- **THEN** its intakes remain stored

#### Scenario: Deleting a substance asks first
- **WHEN** the user starts deleting a substance
- **THEN** nothing is removed until the user confirms that it cannot be undone

#### Scenario: Erasing after a forgotten PIN asks first
- **WHEN** the user taps "Forgot PIN?" on the lock screen
- **THEN** nothing is removed until the user types the confirmation phrase and taps "Erase all"
