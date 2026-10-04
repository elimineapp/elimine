# Design

## Context

- Intakes store `takenAt` (UTC instant), `tzOffsetMin` (device offset when logged), `amount` (nullable) and `updatedAt`. Lists show the wall-clock time in the zone the intake was logged in (`intakeWallTime`), and day grouping uses the same offset.
- `IntakeService` is the single write path: `log`, `delete` (soft delete) and `restore`.
- `IntakeTile` is used by History on the substance screen and by "Recent" on Home. It wraps a `ListTile` in a `Dismissible` and shows the delete snackbar itself. It has no tap action.
- The dose chips (amounts list, toggle-to-clear, "Custom" with `_CustomDoseDialog`) and the time block (time row with date-then-time picking and the future clamp, "Now" / "Yesterday" / "Day before" chips; a null time means "Now") live privately in `substance_screen.dart`.
- Every list, tile and chart watches Drift streams, so a write to `intakes` refreshes them without extra work.

## Goals / Non-Goals

**Goals:**
- One edit sheet reachable from both intake lists, reusing the logging controls rather than duplicating them.
- Undo for edits, consistent with logging and deleting.

**Non-Goals:**
- Moving an intake to another substance.
- Bulk editing or multi-select.
- Any schema change.

## Decisions

**A modal bottom sheet, not a route.**
`showEditIntakeSheet(context, ref, intake)` opens a scroll-controlled modal bottom sheet. It works the same from Home and from the substance screen, keeps the list visible behind it, and needs no route or id lookup. The sheet watches the substance and its doses by `intake.substanceId` for the title, unit and chips.
Alternative: a `/intake/:id` route with a full screen. More navigation for a two-field form, and Home would push a screen outside its shell for a quick fix.

**The sheet edits the wall-clock time in the intake's own zone.**
The time block starts from `intakeWallTime(intake)`. If the user does not change it, `takenAt` and `tzOffsetMin` stay exactly as stored. If they do, the picked date and time are read in the intake's original offset: `takenAt = picked − tzOffsetMin`, offset unchanged. What the user picks is what the lists show and which day it counts on, even for an intake logged in another time zone. "Yesterday" and "Day before" keep the selected time of day, so they are picks like any other. "Now" is different: it means the current moment, so `takenAt` becomes now and the offset the device's current one, as `log` does; the same applies when a picked time is in the future and is clamped to now.
Alternative: read the picked time in the device's current zone and store the current offset, as logging does. An intake logged while traveling would then jump to a different wall-clock time than the one picked whenever it is edited at home.

**Service API: `edit` and `revert`.**
`IntakeService.edit(Intake before, {required DateTime? wallTime, required double? amount})` (a null `wallTime` is "Now") computes the new `takenAt`/`tzOffsetMin` as above, writes them with `amount` and `updatedAt`, and returns whether anything changed (no write when nothing did). `IntakeService.revert(Intake before)` writes back `before`'s `takenAt`, `tzOffsetMin` and `amount`; "Undo" calls it with the row captured before editing. Keeping the offset math in the service keeps it unit-testable without widgets.

**Shared controls extracted from the substance screen.**
- `DoseChips` (in `lib/widgets/`): given the substance's doses, the unit, extra amounts to show and the selected amount, renders the chips and "Custom" with the custom dose dialog, and reports the new selection (`double?`). The substance screen keeps its own preselection rule and passes the last intake's dose as an extra amount; the sheet passes the intake's dose.
- `IntakeTimeField` (in `lib/widgets/`): the time row and the three chips, with the date-then-time picking and the future clamp. It takes the selected time (null = "Now") and the clock, and reports a new selection. The substance screen starts it at null; the sheet starts it at the intake's wall time.
The substance screen's behavior does not change; its existing widget tests guard the extraction.

**The sheet returns a result; the caller shows snackbars.**
The sheet pops with `saved`, `deleted` or nothing. `showEditIntakeSheet` captures the `ScaffoldMessenger` before opening, so the snackbar shows on the screen underneath after the sheet closes. Deletion from the sheet and from a swipe share one helper that deletes and shows "Entry deleted" with "Undo" (→ `restore`).

**Tap on `IntakeTile`.**
The `ListTile` gets `onTap` that opens the sheet; the `Dismissible` stays as it is.

**Strings.**
New English and Russian strings: "Edit entry" (sheet title prefix or semantic label), "Entry updated". "Save", "Delete", "Dose", "Custom", "Undo" and "Entry deleted" exist already.

## Risks / Trade-offs

- [Keeping the original offset when the date moves across a daylight-saving change makes the stored instant one hour off from the true one] → The wall-clock time and the day, which are all the app shows or groups by, are exactly what the user picked; there is no detail within a day.
- [Restoring an old backup after an edit] → Import skips intakes whose ids already exist, so it does not revert edits; the export written after an edit carries the new values. No change to the backup format.
- [Opening the sheet by a tap that was meant as a scroll] → `ListTile` taps do not fire on drags; dismissing the sheet without "Save" changes nothing.

## Migration Plan

None: no schema or data format change. Rolling back the app removes the sheet; edited rows remain valid intakes.
