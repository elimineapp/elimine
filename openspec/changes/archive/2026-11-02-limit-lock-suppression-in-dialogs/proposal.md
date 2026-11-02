# Proposal

## Why

While a system dialog the app opened itself is open (the "Save as" and file picker dialogs of export and import, the biometric prompt), time in the background does not count toward "Lock after", however long it lasts. Android does not tell the app whether the user is still in the dialog or has gone home from it, so a user who taps "Export", leaves the phone and comes back the next day finds the app unlocked as soon as the dialog closes.

## What Changes

- Time spent in the app's own system dialog counts as leaving the app once it is longer than "Lock after" or 5 minutes, whichever is longer. Shorter dialogs still do not lock, so exporting with "Immediately" stays as before.
- After a longer dialog the lock screen shows when the dialog closes; what the dialog returned (the export result, the import preview) is still handled, behind the lock screen.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `app-lock`: "When the app locks" limits how long a system dialog of the app's own does not count as leaving it.

## Impact

- `lib/features/lock/app_lock.dart`: `appHidden` records when a system dialog hid the app, `appShown` locks when it was hidden longer than the limit.
- Tests: `test/app_lock_test.dart` gains cases for long dialogs, with the dialog's result arriving before and after the app is shown again.
- No data, localization or dependency changes.
