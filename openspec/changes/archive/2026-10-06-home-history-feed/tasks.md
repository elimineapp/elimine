# Tasks

## 1. Elapsed time format

- [x] 1.1 Add a pure function in `lib/core/l10n/format.dart` that splits the time between an intake and `now` into a step and its parts: absolute time for minutes and hours, calendar months on wall time with the day clamped to the month's length, then whole days. Verify with unit tests in `test/format_test.dart` covering every step boundary, the anniversary (October 6, 2025 10:00 → October 6, 2026 10:00 is 1 year; 09:59 is 11 mo 29 d) and January 31 → February 28
- [x] 1.2 Add the English and Russian ARB messages from the design's strings table, with compound messages carrying two plural placeholders, and regenerate localizations. Remove `relativeToday` and `relativeYesterday` if nothing else uses them. Verify `flutter gen-l10n` runs cleanly and the analyzer reports no unused keys in code
- [x] 1.3 Replace `relativeDay` with an elapsed formatter and make `lastIntake` use it. Rewrite the relative-day tests in `test/format_test.dart` against the scenarios of the localization delta, English and Russian, including the zero second unit ("5 h ago", "3 days ago") and "1 year 11 mo ago"; verify they pass
- [x] 1.4 Update the existing tests that expect "today", "yesterday" or the old month and year labels on Home tiles or the substance screen header (`test/home_screen_test.dart`, `test/substance_screen_test.dart`) and verify they pass

## 2. Minute tick

- [x] 2.1 Add `minuteTickProvider` (emits now, then at each minute boundary, timer cancelled on dispose) in `lib/app/providers.dart`, and watch it in the Home tile, the substance screen header and the archive screen. Verify with a widget test that a tile reading "just now" reads "1 min ago" after `tester.pump(const Duration(minutes: 1))` with no input, and that existing widget tests finish without pending timers

## 3. Archive

- [x] 3.1 Extend `watchArchivedSubstances` with the latest-intake subquery and return `({Substance substance, int intakes, Intake? last})`. Verify with a test in `test/database_test.dart` that the last intake is the newest non-deleted one and is null without intakes
- [x] 3.2 Show `lastIntake · entriesCount` as the archive entry subtitle, or only the entries count without intakes. Verify in `test/archive_test.dart` that an archived substance shows "0.5 l · 1 year 11 mo ago · 143 entries"-style text and that one without intakes shows "No entries"

## 4. History feed on Home

- [x] 4.1 Add `historyLimitProvider` (starts at 50, grows by 50) and make the history provider pass it to `watchRecentIntakes(limit:)`. Rename the heading to "History" (`historyTitle`) and drop `recentTitle` if unused. Verify with a widget test that 120 intakes show the newest first and that scrolling to the end shows the oldest
- [x] 4.2 Grow the limit when an item within 10 of the end is built and the list length equals the limit. Render the list from `.value` so it does not blank while the next page loads. Verify with a widget test that the scroll offset does not reset when the next page arrives and that the edit sheet and swipe-to-delete still work on an entry from a later page
- [x] 4.3 Move the "Archive (N)" row to directly below "New substance" and above "History". Verify in `test/home_screen_test.dart` that the row sits between them and is hit-testable without scrolling when there are hundreds of intakes, and that it is absent without archived substances

## 5. Back to top

- [x] 5.1 Make `HomeScreen` own a `ScrollController` and add the "Back to top" FAB. It shows past twice the viewport height while scrolling up, hides when scrolling down or near the top, and scrolls to 0 smoothly or with `jumpTo` under `Motion.reducedOf`. Verify with widget tests: it is absent near the top, appears after scrolling far down and then up, hides on scrolling down, tapping it brings the first substance tile into view, and with `disableAnimations` the offset is 0 after a single pump
- [x] 5.2 Add `homeScrollToTopProvider`, bump it in `AppShell` when the already selected Home destination is tapped, and have `HomeScreen` scroll to the top on it. Verify in `test/navigation_test.dart` that reselecting Home far down scrolls to the top, that reselecting at the top changes nothing, and that switching to Analytics and back keeps the scroll position

## 6. Verification

- [x] 6.1 Run `task check` (format, analyzer, tests) and verify it passes
- [x] 6.2 On a device or emulator, in English and Russian: scroll the History feed past several pages, use "Back to top" and the Home reselect, open the archive from its new row and check the last intake, and watch a fresh intake go from "just now" to "1 min ago" without touching the screen. For the phone, install only a same-signed release build with `adb install -r`
