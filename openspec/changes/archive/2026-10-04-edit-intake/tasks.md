# Tasks

## 1. Service

- [x] 1.1 Add `IntakeService.edit(before, wallTime:, amount:)`: keep `takenAt`/`tzOffsetMin` when the wall time is unchanged, use now with the current offset for a null wall time ("Now"), otherwise read the wall time in the intake's own offset, clamp a future result to now with the current offset, write `amount` and `updatedAt`, and return whether anything changed; verify tests in `test/database_test.dart` cover adding a dose, clearing a dose, a time change on an intake with a foreign offset (offset kept, wall time as picked), "Now" (current moment and offset), a future time (clamped) and no change (returns false, `updatedAt` untouched)
- [x] 1.2 Add `IntakeService.revert(before)` restoring `takenAt`, `tzOffsetMin` and `amount`; verify a test edits an intake, reverts it and reads back the original values

## 2. Shared controls

- [x] 2.1 Extract the dose chips and the custom dose dialog from `substance_screen.dart` into a `DoseChips` widget in `lib/widgets/`, and the time row with the "Now" / "Yesterday" / "Day before" chips, date-then-time picking and the future clamp into an `IntakeTimeField` widget; switch the substance screen to them; verify the existing `test/substance_screen_test.dart` passes unchanged
- [x] 2.2 Extract deleting an intake with the "Entry deleted" / "Undo" snackbar from `IntakeTile` into a shared helper used by the swipe; verify the existing swipe tests still pass

## 3. Edit sheet

- [x] 3.1 Add the strings "Edit entry" and "Entry updated" to `app_en.arb` and `app_ru.arb`; verify `task gen` succeeds
- [x] 3.2 Implement `showEditIntakeSheet` (substance name title, `IntakeTimeField` starting at the intake's wall time, `DoseChips` with the intake's dose selected, "Save", "Delete" in the error color; injectable clock) returning saved/deleted/none, and show the "Entry updated" snackbar with "Undo" → `revert`, or the shared delete snackbar; verify widget tests: opening shows the intake's time and dose, an intake from yesterday shows "Yesterday" selected, "Yesterday" on today's 10:00 intake saves yesterday at 10:00, adding a dose and saving updates History and shows "Entry updated", "Undo" restores it, clearing a dose saves no dose, saving unchanged shows no snackbar, dismissing the sheet keeps the intake, "Delete" closes the sheet and offers "Undo"
- [x] 3.3 Give `IntakeTile` an `onTap` opening the sheet, so History and "Recent" both open it; verify a widget test in `test/substance_screen_test.dart` taps a History entry and a test in `test/home_screen_test.dart` taps a "Recent" entry and sees "Edit entry"

## 4. Verification

- [x] 4.1 On a device or emulator, add a dose to an intake logged without one from History, change the time of a "Recent" entry, undo an edit, and delete an entry from the sheet with undo; check that Home tiles, History and the substance chart update each time, and that the sheet fits with the keyboard closed and the custom dose dialog open
- [x] 4.2 Update the Purpose of `openspec/specs/intake-logging/spec.md` to mention editing when archiving this change; verify `openspec validate edit-intake` passes before archiving
- [x] 4.3 Run `task check` and verify formatting, analyzer and tests pass
