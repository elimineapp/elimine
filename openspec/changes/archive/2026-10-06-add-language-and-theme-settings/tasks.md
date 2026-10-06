# Tasks

## 1. Move the Settings screen

- [x] 1.1 Move `lib/features/backup/settings_screen.dart` to `lib/features/settings/settings_screen.dart` and update the imports in `lib/app/router.dart`, `test/settings_screen_test.dart` and `test/navigation_test.dart`, with no behavior change. Verify `flutter analyze` is clean and both tests pass

## 2. Stored preferences

- [x] 2.1 Add to `SettingsService` watchers and setters for the `language` (`en`, `ru`) and `themeMode` (`light`, `dark`) keys, where "System" deletes the key and an unknown value reads as "System", plus a one-shot read of both for app start. Verify with tests in `test/database_test.dart` (or a new `test/settings_service_test.dart`) for the default, each value, going back to "System" and an unknown stored value
- [x] 2.2 Add `localeProvider`, `themeModeProvider` and `initialPreferencesProvider` (defaulting to "System" for both) in `lib/app/providers.dart`. Verify with a provider test that the stream providers emit the new value after a setter runs

## 3. Apply them to the app

- [x] 3.1 Set `locale` and `themeMode` on `MaterialApp.router` in `ElimineApp` from the stream values, falling back to `initialPreferencesProvider` until they emit. Verify with widget tests that pump `ElimineApp` with an initial preference of Russian and dark, and find Russian text and `Brightness.dark` on the very first frame
- [x] 3.2 In `main`, ensure the binding, open the `AppDatabase`, read both preferences and call `runApp` with overrides for `databaseProvider` and `initialPreferencesProvider`. Verify the app starts with `task run` and that `flutter analyze` is clean

## 4. Settings rows

- [x] 4.1 Add English and Russian ARB strings: "Language", "Theme", "Light", "Dark" and separate "System" options for language ("System" / "Системный") and theme ("System" / "Системная"); keep "English" and "Русский" as code constants. Verify with `task gen` and no missing-translation warnings
- [x] 4.2 Turn the week start dialog into a generic choice dialog helper on the Settings screen and use it for "Week starts on". Verify the existing week start tests in `test/settings_screen_test.dart` still pass
- [x] 4.3 Add "Language" and "Theme" rows above "Week starts on" in the "General" section, each showing its current choice and opening the choice dialog. Verify with widget tests in `test/settings_screen_test.dart` that choosing "Русский" switches the screen to Russian at once, that the options read "Системный", "English" and "Русский" in Russian, that choosing "Dark" switches `Theme.of` to dark, and that "System" returns to the device setting
- [x] 4.4 Verify with a test in `test/backup_service_test.dart` that an export made after choosing a language and a theme contains neither

## 5. Verification

- [x] 5.1 Run `task check` (format, analyzer, tests) and verify it passes
- [x] 5.2 On a device or emulator (a release build signed with `android/key.properties`, installed with `adb install -r`): switch language and theme on Settings and check every tab follows at once; restart the app and check it opens in the chosen language and theme without a flash; with "System", toggle the device's dark mode while the app is open and check the app follows
