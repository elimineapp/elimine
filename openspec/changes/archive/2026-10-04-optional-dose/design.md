# Design

## Context

- `intakes.amount` is `REAL NOT NULL`; `doses.amount` stays required. `substances.unit` is `TEXT NOT NULL`, and the form validates it as required.
- The database is at schema version 1 with no migrations and no schema snapshots (`drift_schemas/` does not exist yet). Real data already lives on the phone, so the change needs a real migration, not a reinstall.
- The substance screen keeps the user's dose choice in `_amount` (`double?`, null = not chosen) and derives the selection as `_amount ?? last?.amount ?? doses.first`. "Log" is disabled while nothing is selected.
- `watchDailyTotals` returns `SUM(amount)` and `COUNT(*)` per local day and substance; both the substance chart and cross-substance analytics build on it through `Analytics.build`.
- `ElimineBarChart` draws one rod per bar (stacked for several substances) and pins a tooltip on tap.

## Goals / Non-Goals

**Goals:**
- Intakes without a dose end to end: storage, logging, display and the substance chart.
- A tested first migration that keeps existing data, and a migration workflow for later schema changes.

**Non-Goals:**
- Importing from other apps (export and import come next).
- Editing the dose of an existing intake.
- Changing cross-substance analytics: it counts intakes and already handles this.
- Making doses in the substance's dosage list optional (a listed dose is always a number).

## Decisions

**Nullable `intakes.amount`, migrated with Drift's `make-migrations` workflow.**
Configure the database in `build.yaml` and run `dart run drift_dev make-migrations` once at version 1 to snapshot the current schema, then make the column nullable, bump `schemaVersion` to 2 and run it again. It generates `database.steps.dart` with a typed `stepByStep` helper and migration tests that check every version upgrades to the exact expected schema. The step is `from1To2: m.alterTable(TableMigration(schema.intakes))`: SQLite cannot drop `NOT NULL` in place, and `alterTable` rebuilds the table, copying all rows. A hand-written test also inserts version-1 rows and checks they survive the upgrade unchanged. The Taskfile's `schema:dump` task becomes `db:migrations` running `make-migrations`.
Alternative: a sentinel such as `0` for "no dose". It needs no migration, but every sum, average and display would have to special-case it, and a real zero-dose could never be told apart.

**The unit stays `TEXT NOT NULL`; an empty string means "no unit".**
No schema change is needed, and every display already concatenates the unit. `ElimineFormat.dose(value, unit)` drops the space when the unit is empty, and chart titles use unit-less strings ("Per day", "Daily average"). The unit change warning keeps its current rule (any change of unit on a substance with intakes).

**Dose choice as a nullable record on the substance screen.**
`_amount` becomes `DoseChoice? _choice` with `typedef DoseChoice = ({double? amount})`: null is "not chosen yet", `(amount: null)` is "No dose". The effective selection is: the user's choice, else the last intake's dose (or "No dose" if it had none), else the first listed dose, else "No dose". Something is always selected, so "Log" is always enabled. `IntakeService.log` takes `double? amount`.

**Daily totals report dosed intakes separately.**
The query adds `COUNT(amount) AS dosed` (SQL `COUNT(column)` skips NULLs) and wraps the sum as `COALESCE(SUM(amount), 0)`. `DailyTotal` and `Bucket` carry `dosed`, so `undosed = count - dosed` per bar. Cross-substance analytics keeps using `count`.

**Substance chart picks its measure per range.**
If the range has intakes and none has a dose, the chart counts intakes ("Intakes", whole-number axis; "Year" counts per month like cross-substance analytics, since a daily average of rare intakes would be a fraction under a whole-number axis). Otherwise it sums doses, and bars with undosed intakes get a marker. An empty range keeps the dose chart, so the title does not flip between ranges without data.

**Marker as an extra rod in the bar group.**
`ChartBar` gains an optional `note` (e.g. "1 without dose"); a bar with a note gets a dot and the note as its last tooltip line (instead of a misleading "0 mg" when the day had no dose at all). `ElimineBarChart` adds a second rod to the group with `groupVertically`, so it shares the bar's column: a 6 px round dot 3 px above the bar top (or the baseline), sized in chart units from the chart height, in the substance color. The axis grows by a step when a dot would stick out of the top, and the touch area extends 16 px above every rod so dots and short bars are easy to tap.
Alternatives: a scatter overlay (a second chart stacked on the bar chart, with alignment and touch handling to keep in sync), or a hatched placeholder bar (suggests a quantity that does not exist).

**Strings.**
New English and Russian strings: "No dose" chip and list label, "Logged" without a dose, unit-less chart titles, and a plural "{count} without dose" for tooltips.

## Risks / Trade-offs

- [`alterTable` rebuilds `intakes` on the user's device; a failure would lose data] → Drift runs migrations in a transaction; the generated schema test and the data-preservation test run against version-1 snapshots before shipping; check on the phone that existing history is intact after the upgrade.
- [Dose averages under-count months with undosed intakes] → those months carry a marker and the tooltip states how many intakes had no dose.
- [The dot's size is converted from pixels with the chart's full height minus the bottom titles, an approximation of fl_chart's drawing area] → a slightly off dot size is harmless; check visually on the emulator.

## Migration Plan

1. Ship the migration with the app update; on first launch the database upgrades from version 1 to 2.
2. Rollback is not supported by Drift for downgrades; an older build would refuse the newer schema. Acceptable for a pre-release app with a single user.
