# Tasks

## 1. Migration workflow and nullable dose

- [x] 1.1 Add `build.yaml` with the `elimine` database for drift_dev, run `dart run drift_dev make-migrations` at schema version 1 and replace the Taskfile's `schema:dump` with `db:migrations`; verify `drift_schemas/elimine/drift_schema_v1.json` exists and `task gen` and `task test` pass (migration tests are generated once a second version exists, in 1.2)
- [x] 1.2 Make `intakes.amount` nullable, bump `schemaVersion` to 2, rerun `task db:migrations` and implement `from1To2` with `alterTable` in `stepByStep`; verify the generated migration test passes for 1 → 2
- [x] 1.3 Add a migration test that inserts version-1 substances, doses and intakes and checks all rows and amounts are unchanged after upgrading; verify it passes
- [x] 1.4 Let `IntakeService.log` take `double? amount`; extend `test/database_test.dart` to log and read back an intake without a dose; verify the test passes

## 2. Daily totals

- [x] 2.1 Add `dosed` (`COUNT(amount)`) to `watchDailyTotals`, use `COALESCE(SUM(amount), 0)`, and carry `dosed` through `DailyTotal` and `Bucket`; verify database and analytics tests cover a day with mixed intakes (total from dosed only, count of all, dosed count)

## 3. Logging and display

- [x] 3.1 Add the strings ("No dose", "Logged" without a dose, unit-less chart titles, "{count} without dose") to `app_en.arb` and `app_ru.arb`; verify `task gen` succeeds
- [x] 3.2 Make `ElimineFormat.dose` handle an empty unit and add a formatter for an optional dose; verify `test/format_test.dart` covers "2" without a unit and "No dose"
- [x] 3.3 Substance screen: dose choice type, "No dose" chip first, selection rules and an always-enabled "Log"; verify widget tests: last intake without a dose preselects "No dose", a substance without doses preselects "No dose", logging with "No dose" records a null amount and shows "Logged"
- [x] 3.4 Show "No dose" in intake lists and only the relative day on Home tiles for a last intake without a dose; omit the unit on tiles and in the app bar when empty; verify with a widget test of the Home tile and history entry
- [x] 3.5 Make the unit optional in the substance form; verify a widget test saves a substance with an empty unit and a dose shown as "2"

## 4. Substance chart

- [x] 4.1 Add marker support to `ElimineBarChart` (`ChartBar` marker count and tooltip note, a second rod above the bar or baseline, axis top including it); verify a widget test renders a bar with a marker and its tooltip note
- [x] 4.2 Substance chart: mark bars with undosed intakes, switch to intake counts when the range has intakes but no doses, unit-less titles; verify widget tests for a mixed range (dose bars with markers) and an undosed-only range (title "Intakes")

## 5. Verification

- [x] 5.1 Install over the existing build on the phone and verify the existing history is intact after the 1 → 2 upgrade, then log an intake without a dose and check the snackbar, history, Home tile and chart marker
- [x] 5.2 On the emulator, create a substance without a unit and doses, log several intakes and verify the chart shows intake counts titled "Intakes"; check the marker keeps bars centered
- [x] 5.3 Run `task check` and verify formatting, analyzer and tests pass
