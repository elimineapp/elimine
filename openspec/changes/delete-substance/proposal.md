# Proposal

## Why

A substance created by mistake or for testing stays everywhere: its intakes fill "Recent", history and analytics, and archiving only hides its tile while keeping the history. There is no way to remove it. Archived substances also cannot be reached at all, so an accidental archive cannot be undone.

## What Changes

- "Delete" on the substance edit screen removes the substance, its doses and all its intakes from the device permanently, after a confirmation that names the substance and the number of entries. There is no undo.
- Deleted data is overwritten in the database file rather than only unlinked, so it does not linger on the device.
- A new "Archive" screen lists archived substances; each can be restored to Home or deleted. Home links to it with an "Archive (N)" row when at least one substance is archived.
- Archiving itself is unchanged: it hides the tile and keeps the history in analytics.

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `substances`: deleting a substance with its history; the archive screen with restore and delete.
- `home`: the "Archive (N)" entry.
- `navigation`: the archive screen opens above the tabs.
- `local-data`: deletion of a substance is permanent and leaves no recoverable data.

## Impact

- `SubstanceService`: `delete` (in a transaction: intakes, doses, substance) and `restore`.
- Database: `PRAGMA secure_delete` on every connection and a WAL checkpoint after deleting; no schema change.
- Queries: archived substances with their intake counts; the active intake count for the confirmation.
- UI: a "Delete" button on the edit screen, a new archive screen and route, the Home entry row.
- Localization: new English and Russian strings.
- Tests: service, file-level privacy check and widget tests.
