# Design

## Context

- Substances are archived through `SubstanceService.archive` (sets `archived_at`); `watchSubstancesWithLast` filters archived ones out, while analytics and "Recent" still include their intakes. No screen lists archived substances, and there is no way to unarchive.
- `doses.substance_id` and `intakes.substance_id` reference `substances.id` with foreign keys enforced (`PRAGMA foreign_keys = ON`), without `ON DELETE CASCADE`.
- Intakes are soft-deleted (`deleted_at`), so the database still holds intakes the user removed with a swipe.
- The database runs in WAL mode: writes go to `elimine.sqlite-wal` first and are checkpointed into `elimine.sqlite` later. SQLite only unlinks deleted rows by default; their bytes stay in free pages and in old WAL frames.
- The edit screen confirms "Archive" with a dialog (`_confirm`) and then navigates to `/`.

## Goals / Non-Goals

**Goals:**
- One confirmed action removes a substance with everything that belongs to it, including soft-deleted intakes.
- Removed data does not survive in the database files.
- Archived substances are reachable: restore or delete.

**Non-Goals:**
- Undo after deleting a substance (explicitly declined: permanent with confirmation).
- Deleting several substances at once, or deleting a range of history.
- Editing archived substances or logging intakes for them from the archive screen.

## Decisions

**Hard delete in one transaction, children first.**
`SubstanceService.delete(id)` deletes the substance's intakes (soft-deleted included), then its doses, then the substance, inside `db.transaction`. Explicit order keeps foreign keys satisfied without a schema migration to add `ON DELETE CASCADE`.
Alternative: soft-deleting the substance with a `deleted_at` column. It would need a migration, a filter on every query and the coming export, and would keep exactly the data the user wants gone.

**Overwrite deleted content: `secure_delete` plus a WAL checkpoint.**
`beforeOpen` adds `PRAGMA secure_delete = ON`, so SQLite zeroes the content of deleted rows and freed pages instead of leaving it in place. After a substance is deleted, `PRAGMA wal_checkpoint(TRUNCATE)` copies the WAL into the main file and truncates the WAL, so older frames that still hold the substance's name are gone too. The cost is negligible for a database of this size.
Alternative: `VACUUM` after each deletion. It rewrites the whole file, needs free space for a full copy and still leaves the WAL; `secure_delete` gets the same result incrementally.

**Restore clears `archived_at` and keeps `sort_order`.**
Archived substances keep their order value, so a restored tile returns to its old place.

**Archive screen at `/archive`, outside the shell.**
A list of archived substances (badge, name with unit, "N entries"), each with a menu: "Restore" and "Delete". It pops back when the list becomes empty. A query `watchArchivedSubstances()` returns the substances with their active intake counts; Home watches the same provider for its "Archive (N)" row, placed after "Recent" so it stays out of the daily path.

**One shared confirm-and-delete flow.**
A function in the substance feature shows the dialog with the entry count (`countIntakes(substanceId)`, active intakes only, since soft-deleted ones are not visible to the user), calls `delete`, and shows the "{name} deleted" snackbar. The edit screen then goes to `/`; the archive screen stays.

**Strings.**
"Delete", the confirmation title and body (pluralized entry count, "This cannot be undone."), "{name} deleted", "Archive" (screen title), "Archive ({count})", "Restore" and a pluralized "{count} entries", in English and Russian.

## Risks / Trade-offs

- [A mistaken deletion cannot be undone] → the confirmation names the substance and its entry count and says it is permanent; archiving remains the reversible option and is offered next to it.
- [`secure_delete` slows every delete and update slightly] → negligible at this data size.
- [The file-level test depends on SQLite internals] → it checks only the observable property (the name's bytes are absent from the database and WAL files after deletion) on a real file database, and it fails without `secure_delete`, which guards the setting.
- [An open "Undo" snackbar for an intake of the deleted substance] → restoring updates no rows; harmless.
