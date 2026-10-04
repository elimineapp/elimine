# Proposal

## Why

All history lives only on the phone, and Android cloud backup is disabled on purpose, so a lost phone or a reinstall loses everything. There is also no way to bring in history kept elsewhere. A user-controlled backup file solves both: it restores a device, and a converter written outside the app can turn another tracker's data into the same file and import it.

## What Changes

- A Settings screen, opened from a gear in the Home header, with "Export" and "Import".
- Export writes every substance (archived ones included), its doses and its intakes into one JSON file, saved where the user picks in the system "Save as" dialog (default name `elimine-YYYY-MM-DD.json`). Intakes deleted with a swipe are not exported.
- Import reads such a file through the system file picker, validates all of it before writing anything, shows what will be added and what is already present, and on confirmation adds only the records whose ids are not in the database yet. Importing the same file twice adds nothing.
- The file format is public and versioned, documented in `docs/backup-format.md` for people writing converters: intakes nested in their substance, times as ISO 8601 with the UTC offset of the moment, only ids, names and times required.
- No encryption or password; no automatic backups; no import of other apps' formats.

## Capabilities

### New Capabilities
- `data-backup`: exporting all data to a versioned backup file and importing such files by adding missing records.

### Modified Capabilities
- `home`: the header gains a settings action.
- `navigation`: the Settings screen opens above the tabs.

## Impact

- New dependency: `file_picker` (system "Save as" and file picker dialogs).
- New code: backup format codec (encode, decode, validate), import service (plan and apply in one transaction), Settings screen and route, Home header action.
- New documentation: `docs/backup-format.md`.
- Localization: English and Russian strings for Settings, export and import.
- Tests: codec round trip and validation, import merge rules, widget tests with the file dialogs replaced by fakes.
