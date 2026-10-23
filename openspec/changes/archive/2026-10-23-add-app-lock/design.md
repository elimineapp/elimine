# Design

## Context

- `main` reads the language and theme from the `settings` table before `runApp`, so the first frame is already right (`initialPreferencesProvider`). The lock state has to arrive the same way, or Home flashes before the lock screen.
- `ElimineApp` is a `MaterialApp.router`. Dialogs and the substance sheet are pushed onto the router's navigator, so anything placed in `MaterialApp.builder` above that navigator covers all of them.
- `ElimineApp` already has an `AppLifecycleListener` that re-queries Drift on resume.
- `settings` is a key-value table that backups leave out. `SettingsService` reads and writes it, and a missing key means the default.
- `SubstanceService.delete` already removes rows under `PRAGMA secure_delete = ON` and then runs `wal_checkpoint(TRUNCATE)`. `test/secure_delete_test.dart` checks that the files keep no trace.
- Backup export and import go through `BackupFiles` (the `file_picker` system dialogs), which sends the activity to the background while the dialog is open.
- `MainActivity` is a plain `FlutterActivity`. `allowBackup` is already off.
- F-Droid builds from source. Every dependency must be open source and must not need Google Play services.

## Goals / Non-Goals

**Goals:**
- No frame of app content before unlocking: not at cold start, not on resume, not in recent apps (Android 13+).
- The router, tab state and open sheets survive locking, so unlocking returns the user exactly where they were.
- Lock logic that widget tests can run without a device: biometrics, time and the platform channel behind fakes.

**Non-Goals:**
- Encrypting the database. The lock guards the UI against someone holding the phone. It does not protect files against root access or a forensic copy, which the app's sandbox and `allowBackup="false"` already limit.
- iOS-specific behavior (Face ID wording, app switcher snapshot). The design leaves room for it, but this change only implements Android.
- Locking the planned home-screen widget.

## Decisions

### A lock layer in `MaterialApp.builder`, not a route

`MaterialApp.router`'s `builder` wraps the router's navigator in a `Stack`: the navigator below and, while locked, an opaque `LockScreen` above it. The navigator stays mounted, so state is kept. While locked, it is wrapped in `ExcludeSemantics`, `TickerMode(enabled: false)` and `Offstage`, so screen readers, animations and painting are all off. Unlocking removes the lock screen with a short fade, or at once when animations are turned off in the system.

The lock screen sits in a `Navigator` of its own inside the layer, so its "Forgot PIN?" dialog and text field have an overlay above the app's. System back must not reach the app below while it is locked:
- the layer tells the platform that the framework does not handle back (`SystemNavigator.setFrameworkHandlesBack(false)`), so back and the predictive back gesture leave the app, and absorbs the app's `NavigationNotification`s while locked, restoring the last one on unlock;
- a child of the router's `BackButtonDispatcher`, taking priority while locked, closes the lock screen's own dialog or calls `SystemNavigator.pop()` for any back that still reaches Flutter.

Alternatives: a `/lock` route with a `go_router` redirect would rebuild the tab shell and lose the sheet and scroll state, and pushed dialogs would sit above it. A separate `Navigator` overlay entry has the same ordering problem with dialogs.

### `AppLock` notifier owns the state

A Riverpod `Notifier<AppLockState>` (`lib/features/lock/app_lock.dart`) holds `locked`, the settings (enabled, biometric, lock after), the failure count and the blocked-until time. It:
- starts from what `main` read before the first frame (`initialLockProvider`, like `initialPreferencesProvider`): locked whenever the lock is enabled;
- on `AppLifecycleState.hidden` records the time from `clockProvider`, unless a suppression is active; with "Immediately", it locks right away, so a fast app switch never shows the content;
- on `resumed`, locks when the elapsed time is at least "Lock after";
- exposes `unlockWithPin`, `unlockWithBiometrics`, `setPin`, `changePin`, `disable`, `enableBiometrics`, `setLockAfter` and `eraseAll`.

`hidden` is used rather than `paused` because it fires on both Android and iOS before the app stops being visible.

### Suppression while the app's own system dialogs are open

`AppLock.whileExternal(Future Function() work)` raises a counter for the duration of `work`, and a `hidden`/`resumed` pair inside it is ignored. `SystemBackupFiles` calls are wrapped by the Settings screen, and the biometric prompt is wrapped inside `AppLock`. Wrapping at the call sites keeps `BackupFiles` independent of the lock.

Alternative: a fixed grace period after resume would also skip legitimate locks and still miss slow file dialogs.

### PIN storage: PBKDF2-HMAC-SHA256 with a random salt

The PIN is stored in `settings` under `appLock.pin` as `pbkdf2-sha256$<iterations>$<salt b64>$<hash b64>`, with a 16-byte salt from `Random.secure()`. PBKDF2 is about 20 lines on top of `package:crypto`'s `Hmac`. The iteration count is chosen so that one check takes about 150 ms on a mid-range phone and runs in `Isolate.run`. The comparison runs in constant time. The format carries its own parameters, so the count can be raised later without a migration: a successful check rehashes with the new count.

The PIN's length is stored alongside it (`appLock.pinLength`), so the lock screen can check as soon as enough digits are in, which saves an "OK" tap. That reveals only the length, out of 5 possible values.

Alternatives: a plain SHA-256 is cheap enough to reverse with a lookup table. Argon2 or `cryptography` add a larger dependency for a 10^4–10^8 key space, where the KDF cost matters less than the throttling. Android Keystore-backed storage (`flutter_secure_storage`) would make the PIN unreadable to root, but the database next to it is readable anyway (see Non-Goals).

### Settings keys

All lock state lives in the `settings` table, read and written through `SettingsService` helpers, with no schema change:

| Key | Value | Missing means |
|---|---|---|
| `appLock.pin` | encoded hash | lock off |
| `appLock.pinLength` | `4`–`8` | – |
| `appLock.biometric` | `true` | off |
| `appLock.after` | seconds: `0`, `300`, `900` | 60 |
| `appLock.failures` | count | 0 |
| `appLock.blockedUntil` | ISO 8601 UTC | not blocked |

The lock is "on" exactly when `appLock.pin` exists. Turning it off deletes every `appLock.*` key in one transaction.

### Biometrics through `local_auth`, behind an interface

`Biometrics` (`isAvailable()`, `authenticate(text)`) has a `LocalAuthBiometrics` implementation that uses `local_auth` with `biometricOnly: true`, and tests replace it with a fake, as `BackupFiles` is replaced. "Available" means `getAvailableBiometrics()` contains `BiometricType.strong` or `fingerprint`, so weak face unlock is not offered. The Settings row is labelled "Biometric unlock" rather than "Fingerprint", since Class 3 face unlock goes through the same prompt. `biometricsAvailableProvider` caches the check and is refreshed on every resume, since fingerprints can be enrolled or removed in the system settings meanwhile. The prompt gets a localized title, description and "Use PIN" button and an empty subtitle, because without one Android adds an English "Verify identity".

`local_auth` needs a `FragmentActivity`, so `MainActivity` extends `FlutterFragmentActivity`. That is the only change to the existing activity apart from the channel below.

### Hiding the recent apps preview

A `MethodChannel('elimine/window')` with `setRecentsHidden(bool)` calls `Activity.setRecentsScreenshotEnabled(!hidden)` on API 33 and later, and does nothing on older versions. `AppLock` calls it at startup and whenever the lock is turned on or off. `FLAG_SECURE` is not used, because it would also block screenshots.

### PIN entry UI

One `PinPad` widget (dots, a 3×4 keypad with the biometric key bottom left and delete bottom right) is shared by:
- `LockScreen`, an overlay with the app icon, "Forgot PIN?", the throttling countdown and a shake on a wrong PIN;
- `PinSetupScreen`, a full-screen route above the tabs with "Next" and "Done" steps and the forgotten-PIN warning; it returns the new PIN to its caller;
- a `verifyPin` dialog-sized route used to turn the lock off and before "Change PIN".

Digits are typed on the app's own keypad, not the system keyboard, so they never reach a keyboard app's suggestions or cloud sync.

### Erasing after a forgotten PIN

`AppLock.eraseAll()` runs one transaction that deletes all intakes, doses and substances and every `appLock.*` key, then runs `wal_checkpoint(TRUNCATE)`, the same way `SubstanceService.delete` does. The router is then sent to Home with `router.go('/')`, and the app unlocks. `test/secure_delete_test.dart` gains a case for it.

The dialog asks the user to type a phrase instead of only tapping a button. The phrase is the ARB string `eraseConfirmPhrase`, so each translation chooses its own and the code holds no words. The phrase and the button label are the same words ("Erase all" / "ОЧИСТИТЬ ВСЁ"). Before comparing, both sides are trimmed, runs of whitespace collapse to one space, letters are uppercased and "Ё" becomes "Е", so "очистить все" typed without "ё" is accepted.

Alternatives: a plain confirmation dialog is too easy to tap through by accident, for example by a child. Holding the button down for a few seconds is less obvious and harder to use with TalkBack. Removing the button and pointing to Android's "Clear storage" was considered. It does not stop deliberate harm either, since anyone holding the unlocked phone can clear storage or uninstall the app, and it is much harder for a user who really forgot the PIN. The phrase blocks accidents. Backups are the protection against deliberate harm.

### Throttling

`unlockWithPin` refuses while `now < blockedUntil`. On a wrong PIN it increments `failures`. From the 5th failure on, `blockedUntil = now + 30 s × 2^(failures − 5)`, capped at 1 hour. Success resets both. Times come from `clockProvider`, so tests can move time forward.

## Risks / Trade-offs

- [Changing the system clock skips the wait] `blockedUntil` is wall-clock time. → Accepted: the wait slows guessing and does not stop someone who can change system settings. Elapsed realtime would be lost on reboot.
- [PBKDF2 speed in pure Dart varies across phones] → Run it in an isolate, measure on the emulator and on a real device, and keep the count in the encoded value so it can change later.
- [`hidden` may not fire on some OEM builds when the screen turns off] → A cold start always locks, and the manual check covers screen off and on.
- [Biometric enrollment changes are not detected] `local_auth` cannot tell when a new fingerprint is added. → Accepted for this threat model. Anyone who can enroll a finger already knows the phone's PIN.
- [The recent apps live tile] Opening recent apps from inside the unlocked app shows its live window, which `setRecentsScreenshotEnabled` does not cover. → Only what was on screen a moment before is visible. Once the app is left or locked, its card is blank.
- [`FlutterFragmentActivity` switch affects predictive back or the launch theme] → Check predictive back and the splash screen on Android 14 in the manual step.
- [The planned home-screen widget would show data without the lock] → Out of scope here. The widget change will have to respect `appLock.pin`.
- [A user forgets the PIN without a backup] → Warning on the setup screen. Erasing is the documented and only way out.

## Migration Plan

No data migration. Existing users have no `appLock.*` keys, so the lock is off and nothing changes until they turn it on. Rolling back to a version without the feature ignores the extra keys, so the app opens unlocked.
