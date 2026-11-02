# Design

## Context

`AppLock.whileExternal(work)` raises a counter while one of the app's own system dialogs is open, and `appHidden` returns early while the counter is up, so the `hidden`/`shown` pair that the dialog causes is ignored. The add-app-lock design chose this over a grace period after every resume, which would also skip legitimate locks.

A file dialog of `file_picker` (the system documents UI) is another app's activity. When the user goes home from it, the app's own activity gets no further lifecycle callback: it is already in the background. `onUserLeaveHint` goes to the dialog's activity, and `TRIM_MEMORY_UI_HIDDEN` fires as soon as the dialog opens. So the app cannot tell a user browsing folders from one who left.

## Goals / Non-Goals

**Goals:**
- Bound how long the app can stay unlocked behind its own system dialog.
- Keep quick exports and imports free of the lock screen, even with "Immediately".

**Non-Goals:**
- Telling a user in the dialog from one who left it: there is no signal for that.
- Changing locks outside system dialogs.

## Decisions

**Time is the only measure.** While the counter is up, `appHidden` records the time the app was hidden (the first time, if the dialog hides it more than once). `appShown` compares the time since then with the limit `max(lockAfter, 5 minutes)` and locks when it is reached. The limit only applies to time inside the app's own dialogs; every other return keeps the plain "Lock after" rule, so nothing that locks today stops locking.

5 minutes is far longer than saving or picking a file takes, so a lock after a dialog is rare for someone who stayed in it, and costs only a PIN or a fingerprint. A user who leaves from the dialog for less than the limit still finds the app open; that window is now bounded instead of unlimited. With "Lock after" at 15 minutes, the limit is 15 minutes, as for any other absence.

**Independent of the order of the result and the return.** On Android the dialog's result can reach Dart before or after the app's "shown" event. The recorded time stays until `appShown` consumes it, whether or not `whileExternal` has finished by then, so both orders lock the same way.

Alternative: locking in `whileExternal` when the work finishes. It would miss the case where the app is shown before the result arrives and lock while the app is still hidden in the other.
