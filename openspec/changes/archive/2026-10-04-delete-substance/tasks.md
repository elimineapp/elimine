# Tasks

## 1. Data layer

- [x] 1.1 Add `SubstanceService.delete` (transaction: intakes including soft-deleted, doses, substance; then `wal_checkpoint(TRUNCATE)`) and `SubstanceService.restore`; verify database tests: deletion leaves no rows of that substance in any table, other substances untouched; restore brings the substance back to Home in its old order
- [x] 1.2 Enable `PRAGMA secure_delete = ON` in `beforeOpen`; verify a file-database test (temporary directory) that deletes a substance named "Zebra-test" with intakes, closes the database and finds no "Zebra-test" bytes in the database or WAL files, and that the same test fails with the pragma removed
- [x] 1.3 Add `watchArchivedSubstances()` (with active intake counts) and `countIntakes(substanceId)` queries and their providers; verify database tests for counts that ignore soft-deleted intakes

## 2. Strings

- [x] 2.1 Add the English and Russian strings (Delete, confirmation title and pluralized body, "{name} deleted", Archive title, "Archive ({count})", Restore, "{count} entries"); verify `task gen` succeeds

## 3. Deleting from the edit screen

- [x] 3.1 Add the shared confirm-and-delete flow and a "Delete" button under "Archive" on the edit screen, returning to Home with the snackbar; verify widget tests: confirming deletes the substance and its intakes and shows "{name} deleted", cancelling changes nothing

## 4. Archive screen

- [x] 4.1 Add the `/archive` route and the archive screen (list, Restore, Delete, pop when empty); verify widget tests: Restore puts the substance back on Home, Delete removes it after confirmation
- [x] 4.2 Add the "Archive (N)" row after "Recent" on Home, shown only when something is archived; verify a widget test for both cases

## 5. Verification

- [x] 5.1 On the emulator: archive a substance, open "Archive (1)", restore it; archive it again and delete it from the archive; delete another substance from its edit screen; check that its entries are gone from "Recent" and Analytics
- [x] 5.2 Run `task check` and verify formatting, analyzer and tests pass
