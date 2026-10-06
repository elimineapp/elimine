# Proposal

## Why

The app always follows the device language and the system light or dark mode. Someone with an English phone who prefers the app in Russian, or who wants the app dark on a light system (or the other way round), has no way to get it. Both are common personal preferences and cheap to offer: the app already ships both languages and both themes.

## What Changes

- The Settings screen gets a "Language" row in the "General" section, offering "System", "English" and "Русский". "System" is the default and keeps today's behavior. Language names are written in their own language so a user can always find their way back.
- The Settings screen gets a "Theme" row in the "General" section, offering "System", "Light" and "Dark". "System" is the default and keeps today's behavior.
- A choice applies at once, without a restart, and is kept on the device across restarts. Neither choice is part of backup files.
- The app reads both choices before drawing its first frame, so it never starts in the wrong language or theme and then switches. The native launch screen of Android still follows the system theme for the instant before the app draws.
- The language is chosen inside the app only; the app does not register with Android's per-app language setting.
- The Settings screen moves from `features/backup/` to its own `features/settings/` folder, since it is no longer only about backups.

## Capabilities

### New Capabilities

- `appearance`: how the app looks as a whole, starting with the choice between the system, light and dark themes.

### Modified Capabilities

- `localization`: the interface language follows the device unless the user picks a language in Settings.

## Impact

- Settings screen: two new rows and choice dialogs; the file moves to `lib/features/settings/`, and its test, the router and imports follow.
- Settings service and providers: read, watch and store the language and theme under new keys in the existing `settings` table. No database migration.
- App start: `main` opens the database, reads both choices and hands them to the app before `runApp`.
- `MaterialApp`: gets `locale` and `themeMode` from the choices.
- Localization: new strings for the rows and the "System", "Light" and "Dark" options in English and Russian.
- Backups are unaffected.
