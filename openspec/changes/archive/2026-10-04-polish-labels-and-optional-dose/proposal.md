# Proposal

## Why

A few labels read awkwardly or repeat themselves. "No dose" shows up as if it were a value, while an intake without a dose is simply an intake: the dose is optional, so its absence needs no label. "All years" is longer than it needs to be next to "Week", "Month" and "Year", and the Russian "Единица" on the substance form is ambiguous without "измерения".

## What Changes

- The Analytics range "All years" is renamed to "All" (Russian "Все").
- "No dose" is no longer shown anywhere:
  - Intake lists (History, "Recent") show the dose when there is one and nothing in its place otherwise.
  - The dose picker on the substance screen loses its "No dose" chip. Tapping the selected dose chip again clears the selection; with nothing selected, "Log" records an intake without a dose. Nothing is preselected when the last intake had no dose, or when the substance has no doses and no intakes.
  - The dose chart tooltip no longer says "1 without dose"; a day or month with intakes without a dose shows its number of intakes instead (e.g. "2 intakes").
- The unit field on the substance form is labeled "Unit of measure" (Russian "Единица измерения") instead of "Unit".
- Home tiles, the substance screen title and the archive list show the substance name alone ("Coffee" instead of "Coffee, mg"); the unit still appears with doses ("250 mg · 12 days ago").

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `home`: substance tiles show the name without the unit.
- `analytics`: the "All years" range is named "All" in the ranges, metrics and navigation requirements.
- `intake-logging`: dose selection without a "No dose" chip (a dose chip can be deselected), logging with nothing selected, and intake lists that show nothing for a missing dose.
- `substance-chart`: the tooltip shows the number of intakes instead of "N without dose".
- `substances`: the unit field is labeled "Unit of measure".

## Impact

- `lib/l10n/app_en.arb`, `lib/l10n/app_ru.arb` and the generated `lib/l10n/app_localizations*.dart`: `rangeAllYears` and `fieldUnit` change; `noDose` and `tooltipWithoutDose` go away.
- `lib/features/substance/substance_screen.dart`: dose chips become deselectable, no "No dose" chip.
- `lib/widgets/intake_tile.dart` and `lib/core/l10n/format.dart`: no text for a missing dose.
- `lib/features/substance/substance_chart.dart`: tooltip note.
- `lib/features/home/home_screen.dart`, `lib/features/substance/substance_screen.dart`, `lib/features/archive/archive_screen.dart`: the name without the unit; `nameWithUnit` in `lib/core/l10n/format.dart` goes away.
- Tests: `format_test.dart`, `home_screen_test.dart`, `substance_screen_test.dart`, `analytics_screen_test.dart`, `bar_chart_test.dart` (doc comment and fixtures only).
- No data or backup format changes.
