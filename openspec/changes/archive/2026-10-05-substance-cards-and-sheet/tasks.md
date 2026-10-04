# Tasks

## 1. Week strip data

- [x] 1.1 Add a pure `weekMarks(totals, today, firstWeekday)` next to `AnalyticsPeriod`. It returns 12 flags per substance, oldest first, set when the week had any intake, dosed or not. Verify unit tests in `test/analytics_test.dart` cover:
  - an intake today (last flag set);
  - Tuesday, September 22 with today Sunday, October 4 and Monday start (second from right);
  - Saturday, October 3 with Sunday start (second from right);
  - an intake without a dose (counts);
  - an intake 13 weeks ago (all false);
  - a substance without totals (all false).
- [x] 1.2 Add a Home provider combining `dailyTotalsProvider` (since the start of the 12th week minus one day) and `weekStartProvider` into `weekMarks`. Verify a widget test in `test/home_screen_test.dart` sees the strip of a substance logged today with its last mark filled.

## 2. Home cards

- [x] 2.1 Give `SubstanceBadge` a `filled` option: the icon in the onColor (white on light, surface on dark) on a solid substance-color circle. Verify existing badge uses render unchanged (`task check` analyzer and tests pass).
- [x] 2.2 Replace the two-column grid with full-width tinted cards. Each card has the color at 14% (22% in dark), radius 20, a filled 40 dp badge, the name on up to two lines with an ellipsis, the "250 mg · 12 days ago" line and the 12-mark strip. Keep the existing tile texts. Verify the `home_screen_test` cases for the name without the unit, "Not logged yet" and a last intake without a dose still pass. Add a test that a long name renders without overflow and with `maxLines: 2`.
- [x] 2.3 Rename the "New" tile to a full-width "New substance" row (`newSubstanceTile` → "New substance" / "Новое вещество" in `app_en.arb` and `app_ru.arb`). Verify `task gen` succeeds and a test on an empty database finds only "New substance", which opens the new substance screen.
- [x] 2.4 Make `weekMarks` count intakes per week instead of flags, and shade the marks by count: the substance color at 75% for one intake, 87.5% for two, full for three or more, `outlineVariant` for none. Verify a unit test in `test/analytics_test.dart` sums intakes across the days of a week, and a widget test in `test/home_screen_test.dart` sees marks of weeks with one, two and four intakes get stronger in that order.

## 3. Substance sheet

- [x] 3.1 Add the strings "Chart and history" and "Collapse" to both ARB files. Verify `task gen` succeeds.
- [x] 3.2 Add a `sheetExpanded` flag to `SettingsService` (watch and set, key/value in `settings`). Verify a test in `test/database_test.dart` reads false by default and true after setting. Verify `test/backup_service_test.dart` still shows backups without settings rows.
- [x] 3.3 Turn `SubstanceScreen` into the sheet content: a `DraggableScrollableSheet` (`snap`, `snapSizes: [collapsed, 1.0]`) whose controller drives one `CustomScrollView`, holding:
  - the header (handle, filled badge, name, last-intake line, settings action) when collapsed, and ("Collapse", badge, name, settings action) when expanded;
  - the time, dose and "Log" controls;
  - the "Chart and history" row with the intake count, shown only while collapsed;
  - the chart and the history.

  Compute `collapsed` from the measured logging block plus a chart peek. Keep the content pumpable on its own, and verify the existing `test/substance_screen_test.dart` logging, dose and history tests pass against it.
- [x] 3.4 Wrap the sheet content in its own `ScaffoldMessenger` + transparent `Scaffold`. On "Log":
  - when collapsed, pop and show the snackbar on Home's messenger;
  - when expanded, stay and show it on the sheet.

  Verify widget tests:
  - collapsed "Log" closes the sheet, Home shows "Logged 250 mg" with "Undo" and the tile shows "250 mg · today";
  - expanded "Log" keeps the sheet expanded, the intake is first in History and "Undo" removes it.
- [x] 3.5 "Chart and history" and "Collapse" animate the controller to expanded or collapsed. Collapsing resets the scroll to the top. Reaching the expanded size sets `sheetExpanded`. Verify widget tests: tapping "Chart and history" shows the "Collapse" action and History, and tapping "Collapse" brings back the "Chart and history" row.
- [x] 3.6 Add the expand hint: when `sheetExpanded` is unset, lift the sheet by about 28 dp after the opening animation and settle back. Verify a widget test with the flag unset sees the sheet size rise and return, and a test with the flag set sees no change.

## 4. Navigation

- [x] 4.1 Add a modal sheet `Page` (a `ModalBottomSheetRoute` with scroll control, drag, safe area and a dismissing barrier). Move `/substance/:id` under `/` as `substance/:id` with `parentNavigatorKey` = root, keeping its `edit` child and `/substance/new`. Verify `test/navigation_test.dart`:
  - tapping a tile shows the sheet over Home with the bottom navigation covered;
  - system back closes it and leaves Home;
  - a tap on the barrier closes it;
  - the settings action opens the edit screen, and back returns to the sheet.
- [x] 4.2 After creating a substance, show Home with the new substance's sheet collapsed (replace `/substance/new` with the sheet route). Verify a test in `test/substance_form_test.dart`: saving a new substance shows its sheet over Home, and closing it shows its tile.
- [x] 4.3 Verify that archiving and deleting from the edit screen opened from a sheet close the sheet too. Add tests in `test/substance_form_test.dart`: after "Archive" or "Delete", Home is shown with no sheet and no tile for that substance.

## 5. Verification

- [x] 5.1 On a device or emulator, in light and dark theme:
  - open a substance, see the hint once, then drag the sheet up and down;
  - tap "Chart and history" and "Collapse";
  - log from both states, and undo;
  - swipe the dose chart horizontally inside the expanded sheet and check the sheet does not move;
  - open "Edit entry" from History over the expanded sheet and delete with undo;
  - check long names wrap on the cards;
  - check the collapsed sheet shows the chart's edge at the largest system font size.
- [x] 5.2 When archiving this change, update the Purpose of `openspec/specs/home/spec.md` if it still says "tiles" in a grid sense. Verify `openspec validate substance-cards-and-sheet --strict` passes.
- [x] 5.3 Run `task check` and verify formatting, analyzer and tests pass.
