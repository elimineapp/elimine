# Proposal

## Why

An intake cannot be changed once logged. A dose remembered later (now that intakes may have no dose) or a wrong time can only be fixed by deleting the entry and logging it again, which also loses its original time unless it is picked by hand. Deleting exists, but only as a swipe, which is easy to miss: there is no visible way to remove an entry logged by mistake.

## What Changes

- Tapping an intake in History or "Recent" opens an "Edit entry" sheet with the intake's time and dose, the same controls as logging: a time row with date and time pickers, the "Now", "Yesterday" and "Day before" chips, dose chips, "Custom", and tapping the selected dose to clear it.
- "Save" writes the new time and dose and shows a snackbar "Entry updated" with "Undo", which puts back the previous values. Saving without changes just closes the sheet.
- The sheet has a "Delete" button that deletes the intake exactly like a swipe: snackbar "Entry deleted" with "Undo".
- Swiping an intake away keeps working as before.
- The substance of an intake cannot be changed; an entry logged under the wrong substance is deleted and logged again.

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `intake-logging`: new requirement for editing an intake; deleting an intake also from the edit sheet.
- `home`: entries under "Recent" open the edit sheet on tap.

## Impact

- `IntakeService`: an update method for time and dose (recomputing the time zone offset when the time changes) and a way to restore previous values for "Undo".
- New edit sheet widget; the dose chips, custom dose dialog and date/time picking move out of the substance screen into shared widgets used by both.
- `IntakeTile` gets an `onTap` that opens the sheet.
- Localization: new English and Russian strings.
- Tests: service and widget tests. No database schema change: `updatedAt` already exists.
