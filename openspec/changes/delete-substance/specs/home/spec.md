# Spec Delta

## ADDED Requirements

### Requirement: Archive entry
When at least one substance is archived, Home SHALL end with an "Archive (N)" row, N being the number of archived substances, that opens the archive screen. Without archived substances the row SHALL NOT be shown.

#### Scenario: Archived substances exist
- **WHEN** two substances are archived
- **THEN** Home ends with "Archive (2)", which opens the archive screen

#### Scenario: Nothing archived
- **WHEN** no substance is archived
- **THEN** Home shows no archive row
