# Design

## Context

- `MaterialApp.router` in `lib/app/app.dart` already builds a light `theme` and a dark `darkTheme` from one seed color, and leaves `themeMode` and `locale` unset, so both follow the device. Substance colors pick their light or dark step from `Theme.of(context).brightness`; nothing reads `MediaQuery.platformBrightness` directly.
- Every date and number format takes `AppLocalizations.localeName`, so setting `MaterialApp.locale` changes the format along with the strings.
- Device preferences live in the key-value `settings` table, where a missing key means the default. `SettingsService` reads them through Drift streams, exposed as `StreamProvider`s (`weekStartProvider`). A stream's first value arrives after the first frame.
- `main` calls `runApp` at once, and `databaseProvider` opens the database lazily. Tests override `databaseProvider` with an in-memory database.
- The Settings screen lives in `lib/features/backup/settings_screen.dart` and asks for the week start in a `SimpleDialog` with a `RadioGroup` of `RadioListTile`s.

## Goals / Non-Goals

**Goals:**
- The first frame already uses the stored language and theme.
- A change in Settings applies to the running app without a restart.
- The three choice rows on Settings share one dialog.

**Non-Goals:**
- Android's per-app language setting (`locale_config.xml`, `AppCompatDelegate`) and a native launch screen that follows the app's theme.
- Languages other than English and Russian, or a theme other than the existing light and dark.

## Decisions

### Stored as absent-or-explicit keys

Two new keys: `language` with `en` or `ru`, and `themeMode` with `light` or `dark`. Choosing "System" deletes the key, in line with the table's rule that a missing key means the default. A value the app does not know, for example a language removed in a later version, reads as "System".

Alternative: store `system` explicitly. It works the same but leaves two ways to say "default".

### Read before `runApp`, then follow the stream

`main` calls `WidgetsFlutterBinding.ensureInitialized()`, creates the `AppDatabase`, reads both keys in one query through `SettingsService`, and calls `runApp` with `ProviderScope` overrides for `databaseProvider` (the same database, so there is one connection) and for a new `initialPreferencesProvider` holding what was read.

`localeProvider` and `themeModeProvider` are `StreamProvider`s over the two keys, like `weekStartProvider`. `ElimineApp` uses each stream's value, falling back to the initial preference until the stream emits. When there is no override, as in tests, the initial preferences are "System" for both.

Opening the database before the first frame moves work that Home does on its first frame anyway; the native launch screen covers the wait.

Alternatives: keep the native launch screen until the streams emit (needs a plugin or a deferred first frame, and still blocks on the same query); `SharedPreferences` for these two keys (a second store for device preferences, and still asynchronous on Android).

### Locale and theme mode mapping

`locale` is `null` for "System", so Flutter's own resolution against `supportedLocales` keeps falling back to English, the first supported locale. Otherwise it is `Locale('en')` or `Locale('ru')`. `themeMode` maps directly to `ThemeMode.system`, `.light` and `.dark`.

### Language names are not translated

"English" and "Русский" are constants in code, not ARB strings, so no translation can change them. The "System" option is translated, with separate ARB keys for the language and the theme dialogs, because Russian agrees in gender: "Системный" (язык) and "Системная" (тема). Row titles and the "Light" and "Dark" options are ordinary ARB strings.

### One choice dialog for all three rows

The week start dialog becomes a generic helper on the Settings screen that takes a title, the options with their labels and the current value, and returns the picked one, or null when dismissed. "Week starts on", "Language" and "Theme" all use it. The "General" section lists "Language", "Theme" and "Week starts on" in that order.

### Settings screen moves to `features/settings/`

`settings_screen.dart` moves to `lib/features/settings/` and its test keeps its name. `backup_files.dart`, `backup_format.dart` and `backup_service.dart` stay in `features/backup/`. The move is its own commit-sized step in tasks so that the diff of the new rows stays readable.

## Risks / Trade-offs

- [Native launch screen in the wrong theme] With "Light" on a dark device, the Android launch screen is dark for the moment before Flutter draws. → Accepted; the first Flutter frame is already right.
- [Slow start if the database migrates] A future schema migration runs before the first frame instead of during it. → The launch screen stays up; migrations are rare and small.
- [Two sources of truth for one frame] Until the stream emits, the app shows the initial preference; a write in that window could be briefly overridden. → The stream emits within the first frames, long before a user can reach Settings.

## Migration Plan

No database migration: the keys go into the existing `settings` table. Existing installs have neither key and keep following the device.
