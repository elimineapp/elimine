# Tasks

## 1. Labels

- [x] 1.1 In `lib/l10n/app_en.arb` and `app_ru.arb`, set `rangeAllYears` to "All" / "Все" and `fieldUnit` to "Unit of measure" / "Единица измерения", run `flutter gen-l10n`, and verify the generated `app_localizations_*.dart` carry the new strings
- [x] 1.2 Update `test/analytics_screen_test.dart` to tap "All" instead of "All years", and add a substance form test asserting the unit field is labeled "Unit of measure"; verify both pass with `flutter test`

## 2. Dose picker without "No dose"

- [x] 2.1 In `lib/features/substance/substance_screen.dart`, remove the "No dose" chip and make each dose chip set `_choice = (amount: selected ? amount : null)`; update the `DoseChoice` and `_choice` doc comments; verify by reading that the default selection logic is unchanged
- [x] 2.2 Update `test/substance_screen_test.dart`: a last intake without a dose preselects no chip and there is no "No dose" chip; a substance without doses shows only "Custom", nothing selected, and "Log" records an intake without a dose; tapping a selected dose chip clears it and "Log" then records no dose; verify with `flutter test test/substance_screen_test.dart`

## 3. Lists and chart tooltip

- [x] 3.1 Remove `optionalDose` from `lib/core/l10n/format.dart` and make `lib/widgets/intake_tile.dart` show no `trailing` when the amount is null; update `test/format_test.dart` (drop the `optionalDose` cases), `test/home_screen_test.dart` ("Recent" entry shows no "No dose") and the history assertion in `test/substance_screen_test.dart`; verify with `flutter test`
- [x] 3.2 In `lib/features/substance/substance_chart.dart`, make the note `tooltipIntakes(countFor(id))` when the bucket has intakes without a dose; update the `ChartBar.note` doc comment and the `test/bar_chart_test.dart` fixtures to the new wording; add or extend a substance chart test asserting a mixed day reads "250 mg" and "2 intakes"; verify with `flutter test`
- [x] 3.3 Delete `noDose` and `tooltipWithoutDose` from both ARB files, run `flutter gen-l10n`, and verify `grep -rn 'noDose\|tooltipWithoutDose\|No dose\|Без дозы' lib test` finds nothing
- [x] 3.4 In `lib/features/home/home_screen.dart`, show `substance.name` instead of `nameWithUnit` on the tile; extend `test/home_screen_test.dart` to assert a tile of a substance with a unit shows "Coffee" and not "Coffee, mg"; verify with `flutter test test/home_screen_test.dart`
- [x] 3.5 Show `substance.name` in the substance screen title and the archive list, delete the now unused `nameWithUnit`; verify `grep -rn nameWithUnit lib test` finds nothing and `flutter analyze` is clean

## 4. Verification

- [x] 4.1 Run `task check` (format, analyzer, tests) and verify it passes
- [x] 4.2 Manual check on a device or emulator in English and Russian: Analytics shows "All"/"Все"; the substance form reads "Unit of measure"/"Единица измерения"; the dose picker has no "No dose" chip and a selected dose can be tapped off and logged without a dose; History and "Recent" show nothing for that intake; the dose chart tooltip for that day shows the intake count; Home tiles, the substance screen title and the archive list show the name without the unit
