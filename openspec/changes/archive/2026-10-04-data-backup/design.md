# Design

## Context

- Three tables: `substances` (id, name, unit, color, icon, sort_order, archived_at, created_at), `doses` (id, substance_id, amount, sort_order) and `intakes` (id, substance_id, amount nullable, taken_at UTC, tz_offset_min, created_at, updated_at, deleted_at). Ids are UUIDv7 strings.
- Intakes are soft-deleted; substances are archived or, since the last change, deleted permanently with their intakes.
- There is no file I/O yet, no Settings screen, and the Home header has no actions. Colors and icons are keys into fixed maps in `lib/core/appearance.dart`.
- The app targets Android now and possibly iOS later.

## Goals / Non-Goals

**Goals:**
- A backup that restores a device exactly (same ids, times, offsets, doses, order, archive state).
- A format simple enough to produce by hand or from a script.
- Import that is safe to repeat and never destroys existing data.

**Non-Goals:**
- Encryption or passwords, automatic or scheduled backups, sharing through the share sheet.
- Replacing the database on import, or updating records that already exist.
- Reading other apps' formats (converters live outside the app).
- Carrying soft-deleted intakes, creation and update timestamps, or the archive date across.

## Decisions

**Format: one JSON document, intakes nested in their substance.**

```json
{
  "format": "elimine-backup",
  "version": 1,
  "exportedAt": "2026-10-04T14:05:00+10:00",
  "substances": [
    {
      "id": "01a1044e-8cdc-79fb-bc15-17f680997024",
      "name": "Coffee", "unit": "mg", "color": "orange", "icon": "coffee",
      "archived": false, "doses": [100, 200],
      "intakes": [
        {"id": "01a10...", "takenAt": "2026-10-04T13:25:00+10:00", "amount": 100}
      ]
    }
  ]
}
```

Nesting removes cross-references a converter could get wrong. `takenAt` with its offset carries both `taken_at` and `tz_offset_min` in one readable value; `Z` means offset 0. Substance order is the list order. `archived` is a boolean; an archived import gets the import time as its archive date. Not exported: soft-deleted intakes, `created_at`/`updated_at` (set to the import time), `sort_order` (derived from list order).
Alternatives: flat tables mirroring the schema (exact but awkward to write by hand), CSV (cannot hold the substance settings in one file), SQLite file copy (opaque, tied to the schema version, risky to merge).

**Codec as pure Dart with explicit validation.**
`lib/features/backup/backup_format.dart` turns database rows into the JSON map and parses a JSON string into typed records, collecting the first error with a path such as `substances[0].intakes[11].takenAt`. Dart's `DateTime.parse` drops the offset, so `takenAt` is parsed with a small pattern that keeps the `±HH:MM`/`Z` suffix as minutes. Checks: `format` and `version` (≤ supported), UUID-shaped unique ids, non-empty names, positive doses and amounts, times with an offset and not in the future. Unknown `color`/`icon` keys fall back to the defaults instead of failing, so newer palettes do not break older apps.

**Import in two steps: plan, then apply in one transaction.**
`BackupService.plan(records)` queries which substance and intake ids already exist and returns counts (to add, already present). `apply` inserts the missing substances (appended after the current maximum `sort_order`, in file order, with their doses), then the missing intakes, inside `db.transaction`, so a failure leaves the database untouched. Existing ids are skipped without comparing contents ("the database wins"). An intake whose id exists under another substance is also skipped.
Alternative: replace mode. It would allow an exact restore over existing data but adds a destructive path; restoring onto an empty install already gives an exact copy.

**File dialogs through `file_picker`, behind a small interface.**
`file_picker` (13.x) provides the Android "Save as" dialog (`saveFile` with bytes) and the open dialog (`pickFiles` with data), and works on iOS later. The open dialog uses `FileType.any`: providers often report JSON as `application/octet-stream`, and the content check is what matters. A `BackupFiles` interface with a `file_picker` implementation is provided through Riverpod, so widget tests substitute a fake.

**Settings screen at `/settings`, outside the shell.**
A gear action in the Home app bar opens it. It holds "Export" and "Import" list tiles with one-line explanations. Import shows the preview in a dialog ("Add 2 substances and 340 intakes? 15 already present will be skipped.") with "Import" and "Cancel"; errors show in a dialog with the message and its path.

**Format documentation.**
`docs/backup-format.md` describes every field, the defaults, the color and icon keys, the validation rules, the merge rule and a full example; a test parses the example from the document so it cannot drift from the code.

## Risks / Trade-offs

- [The backup file is plain text with sensitive history] → the user chooses where it goes; documented in the format doc; encryption stays out of scope by decision.
- [Restoring an old backup brings back substances deleted since] → the preview counts what will be added before anything is written.
- [Large histories in memory] → years of rare intakes are a few thousand records, well under a megabyte.
- [`file_picker` behavior differs between Android versions and document providers] → manual check on the emulator and the phone, saving to Downloads and reading back.

## Migration Plan

No schema change. The format starts at version 1; later schema changes bump it, and the app keeps reading all older versions.
