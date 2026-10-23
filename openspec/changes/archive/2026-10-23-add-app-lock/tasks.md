# Tasks

## 1. Dependencies and Android

- [x] 1.1 Add `local_auth` and `crypto` to `pubspec.yaml` and run `task deps`. Verify that `flutter pub deps` lists no package that depends on Google Play services
- [x] 1.2 Change `MainActivity` to extend `FlutterFragmentActivity` and add the `elimine/window` channel with `setRecentsHidden(bool)` (`setRecentsScreenshotEnabled` on API 33+, nothing below). Verify that `flutter build apk --debug` succeeds and the app still starts on the emulator

## 2. PIN hashing and stored settings

- [x] 2.1 Add `lib/features/lock/pin_hash.dart`: PBKDF2-HMAC-SHA256 over `package:crypto`, a 16-byte salt from `Random.secure()`, the `pbkdf2-sha256$iter$salt$hash` encoding and a constant-time check run in `Isolate.run`. Verify with `test/pin_hash_test.dart`: an RFC 6070-style known vector, the same PIN with two salts gives different encodings, a wrong PIN fails, and an encoding with a lower iteration count still verifies
- [x] 2.2 Pick the iteration count by timing one check on the emulator (target about 150 ms) and record the measurement in a comment next to the constant
- [x] 2.3 Add the `appLock.*` reads and writes to `SettingsService`, including `readLock()` for `main`, and a `clearLock()` that deletes every `appLock.*` key in one transaction. Verify with tests in `test/preferences_test.dart` for the defaults, a round trip of each key, and `clearLock()` leaving `language` and `themeMode` in place
- [x] 2.4 Verify with a test in `test/backup_service_test.dart` that an export made with the lock on contains no `appLock` key or PIN hash, and that importing a backup leaves the `appLock.*` keys unchanged

## 3. Lock state

- [x] 3.1 Add the `Biometrics` interface with `LocalAuthBiometrics` (strong or fingerprint only, `biometricOnly: true`) and a `FakeBiometrics` for tests, plus a `RecentsWindow` wrapper around the channel with a fake
- [x] 3.2 Add the `AppLock` notifier and `initialLockProvider` (locked when enabled at start), and read the lock in `main` before `runApp`. Verify with unit tests on a `ProviderContainer` with a fake clock: a cold start is locked, the right PIN unlocks, a wrong PIN counts a failure
- [x] 3.3 Implement the lifecycle rules: record `hidden` time, lock on `resumed` once "Lock after" has passed, lock on `hidden` for "Immediately", and `whileExternal` suppression. Verify with tests for 20 s and 2 min absences at "1 minute", 2 s at "Immediately", and a 3 min `whileExternal` absence at "Immediately"
- [x] 3.4 Implement throttling (from the 5th failure 30 s doubling up to 1 h, persisted, reset on success, biometrics allowed while waiting). Verify with tests for the 5th and 6th failures, the cap, a recreated container that keeps the wait, and a biometric success that resets the count
- [x] 3.5 Implement `setPin`, `changePin`, `disable`, `enableBiometrics` and `setLockAfter`, calling `setRecentsHidden` on start, on enable and on disable. Verify with tests that disabling forgets all lock keys, that `changePin` keeps the old PIN until the new one is set, that a failed biometric check leaves biometrics off, and that the fake window receives `true` and then `false`
- [x] 3.6 Implement `eraseAll`: one transaction deleting intakes, doses, substances and `appLock.*`, then `wal_checkpoint(TRUNCATE)`, then unlock. Verify with a new case in `test/secure_delete_test.dart` that "Zebra-test" is gone from the files, and a test that language, theme and week start remain

## 4. PIN entry UI

- [x] 4.1 Add the English strings to `app_en.arb` and the Russian ones to `app_ru.arb` ("Security", "App lock", "Biometric unlock", "Lock after" with its four options, "Change PIN", "Enter PIN", "Choose a PIN", "Confirm the PIN", "Next", "Done", "Wrong PIN", "PINs do not match", the countdown, "Forgot PIN?", the erase dialog with "Erase all" and `eraseConfirmPhrase` ("ERASE ALL" / "ОЧИСТИТЬ ВСЁ"), the forgotten-PIN warning, the biometric prompt reason). Run `task gen` and verify that the analyzer reports no missing translations
- [x] 4.2 Add the `PinPad` widget (dots, keypad, optional biometric key, delete, a shake on error, semantics labels for each key and "N of M digits entered"). Verify with a widget test that taps fill and clear dots, that `onComplete` fires at the given length, and that keys have semantics labels
- [x] 4.3 Add `PinSetupScreen` (choose, then confirm, 4–8 digits, "Next" disabled under 4, mismatch restarts, warning text) as a route above the tabs that returns the PIN. Verify with widget tests for the matching, mismatching, too-short and back-out cases from the spec
- [x] 4.4 Add the `verifyPin` route that asks for the current PIN, applies throttling and offers biometrics when they are on. Verify with widget tests for right and wrong PINs

## 5. Lock screen and app shell

- [x] 5.1 Add `LockScreen` (icon, "Enter PIN", `PinPad`, countdown while blocked, "Forgot PIN?") and show the biometric prompt on appear when biometrics are on. Verify with widget tests for the right PIN unlocking, a wrong PIN showing "Wrong PIN", the keypad disabled with a countdown after 5 failures, and the fake biometric success unlocking without taps
- [x] 5.2 Mount the lock layer in `MaterialApp.builder` above the router (`Offstage`, `ExcludeSemantics` and `TickerMode` on the content while locked, a fade out that respects reduced motion) and make system back on the lock screen move the app to the background. Verify with a widget test that selects "Year" on Analytics, locks, unlocks and still sees "Year", and one that checks no substance name is in the semantics tree while locked, including with an open dialog
- [x] 5.3 Add the "Forgot PIN?" dialog: a text field, "Cancel", and "Erase all", which stays disabled until the field matches `eraseConfirmPhrase` after normalization (trim, collapse spaces, uppercase, "Ё" → "Е"). It calls `eraseAll` and goes to Home. Verify with unit tests for the normalization and widget tests that "Erase all" is disabled when empty, with "ERASE" and with the Russian phrase in the English interface, that " очистить  все" enables it in Russian, that "Cancel" keeps the data, and that "Erase all" opens an empty Home with the lock off

## 6. Settings section

- [x] 6.1 Add the "Security" section between "General" and "Backup": the "App lock" switch (on runs `PinSetupScreen`, off runs `verifyPin`), "Biometric unlock" only when `Biometrics.isAvailable()`, "Lock after" through the existing `_choose` dialog, and "Change PIN". Verify with widget tests in `test/settings_screen_test.dart` for the default state, the rows shown with and without biometrics, turning on and off, and changing the PIN
- [x] 6.2 Wrap "Export" and "Import" in `AppLock.whileExternal`. Verify with a widget test at "Immediately" that a fake `BackupFiles` save which triggers a `hidden`/`resumed` pair leaves the app unlocked and shows the export snackbar

## 7. Documentation

- [x] 7.1 Add the app lock to the feature list in `README.md` and to both `fastlane/metadata/android/*/full_description.txt`, including that the PIN cannot be recovered without erasing data. Verify that the texts match the spec's behavior

## 8. Verification

- [ ] 8.1 Run `task check` (format, analyzer, tests) and verify that it passes
- [x] 8.2 On the Android 14 emulator, and on a device with a fingerprint sensor using a release build signed with the release key (`adb install -r`, never uninstall): turn the lock on, check that a cold start shows the lock screen first without a flash of Home, that the fingerprint unlocks without a tap, that switching away for 20 s does not lock and 2 min does, that the screen off for over a minute locks, that the recent apps card is blank while screenshots work, that exporting a backup at "Immediately" does not lock, that 5 wrong PINs start the countdown, that "Forgot PIN?" → typing the phrase → "Erase all" works (on the emulator only), including typing the Russian phrase with the system keyboard, and that predictive back and the splash screen still behave as before the `FlutterFragmentActivity` change
