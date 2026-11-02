# Tasks

## 1. Lock

- [x] 1.1 In `lib/features/lock/app_lock.dart`, add `externalLimit` (5 minutes); in `appHidden`, while a system dialog is open, record the time the app was hidden instead of ignoring it; in `appShown`, lock when that time is at least `max(lockAfter, externalLimit)` ago; verify `flutter analyze` reports no issues
- [x] 1.2 In `test/app_lock_test.dart`, keep the 3-minute dialog case unlocked and add: "Immediately" with a 6-minute dialog locks, with the dialog's result arriving both before and after the app is shown again; "15 minutes" with a 10-minute dialog stays open and with a 16-minute one locks; verify `flutter test test/app_lock_test.dart` passes

## 2. Verification

- [x] 2.1 Run `task check` (format, analyzer, tests) and verify it passes
