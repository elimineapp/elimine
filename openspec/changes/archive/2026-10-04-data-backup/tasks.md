# Tasks

## 1. Format and codec

- [x] 1.1 Add `backup_format.dart` with the typed records, `encode` from database rows and `decode` with validation and error paths, including the offset-preserving `takenAt` parser; verify unit tests: round trip keeps ids, names, doses, amounts, times and offsets; each validation rule rejects with the expected path; unknown color and icon fall back; a newer version is rejected
- [x] 1.2 Write `docs/backup-format.md` (fields, defaults, color and icon keys, validation, merge rule, full example); verify a test that extracts the example JSON from the document and decodes it without errors

## 2. Import and export service

- [x] 2.1 Add `BackupService` with `export` (all substances, doses and non-deleted intakes, in order) and `plan`/`apply` for import in one transaction; verify database tests: restore into an empty database reproduces the data, a second import adds nothing, older intakes are added to an existing substance id, existing records are left unchanged, new substances are appended after existing ones

## 3. Files and Settings

- [x] 3.1 Add `file_picker`, the `BackupFiles` interface with its implementation and a provider; verify `flutter pub get` and `flutter build apk --debug` succeed
- [x] 3.2 Add the English and Russian strings (Settings, Export, Import, descriptions, preview, success and error messages); verify `task gen` succeeds
- [x] 3.3 Add the `/settings` route, the Settings screen with Export and Import, and the gear action in the Home header; verify widget tests with a fake `BackupFiles`: export saves a file named `elimine-YYYY-MM-DD.json` and shows the snackbar; import of a valid file shows the preview and adds data on confirm; an invalid file shows the error and writes nothing; cancelling either dialog does nothing

## 4. Verification

- [x] 4.1 On the emulator: export to Downloads, delete a substance, import the file and check it is back with its history; import again and check the preview says nothing is new
- [x] 4.2 Run `task check` and verify formatting, analyzer and tests pass
