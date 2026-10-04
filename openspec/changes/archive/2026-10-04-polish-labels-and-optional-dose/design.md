# Design

## Context

The dose picker on the substance screen keeps its state in a `DoseChoice` record (`({double? amount})`), where a null amount already means "no dose" and a null `_choice` means "use the default". The "No dose" chip is just the chip that sets `amount: null`. Intake lists render the dose through `optionalDose`, which falls back to the `noDose` string. The dose chart passes `tooltipWithoutDose(n)` as the bar's `note`, which also drives the dot above the bar.

## Goals / Non-Goals

**Goals:**
- Remove every user-visible "No dose" / "N without dose" text while keeping the ability to log an intake without a dose.

**Non-Goals:**
- No change to how intakes without a dose are stored, exported, counted or summed.
- No change to the dot that marks days with intakes without a dose on the dose chart; only its tooltip text changes.
- No change to the "Logged" snackbar, which already says nothing about a dose.

## Decisions

- **A selected dose chip toggles off.** Each dose `ChoiceChip` sets `_choice = (amount: selected ? amount : null)` from its `onSelected(bool)`, so the record type and the default logic stay as they are. The default with no last dose and no doses is already `amount: null`, which now shows as "nothing selected". Alternative considered: keep a "No dose" chip as a control and hide the label only in lists. Rejected because the user wants the concept gone from the UI.
- **A missing dose renders as nothing.** `optionalDose` is removed. `IntakeTile` omits `trailing` when the amount is null, so the row lays out as a plain time/name row instead of leaving an empty `Text`.
- **The chart note becomes the intake count.** For a bucket with intakes without a dose, the note is `tooltipIntakes(countFor(id))`, the same "2 intakes" string the counting chart already uses. A day with only intakes without a dose then reads "1 intake" rather than a misleading "0 mg" or nothing at all. The `note` field keeps driving the dot, so `ElimineBarChart` does not change, apart from its doc comment example.
- **The name stands alone.** `nameWithUnit` ("Coffee, mg") is removed and its three callers (Home tile, substance screen title, archive list) show `substance.name`. The unit stays where it qualifies a number: doses, the dose chart title and the unit field. The archive screen spec already lists only the name, so only the Home tile requirement changes.
- **Strings.** `rangeAllYears` becomes "All" / "Все" (the key stays, since it still names the all-years range). `fieldUnit` becomes "Unit of measure" / "Единица измерения". `noDose` and `tooltipWithoutDose` are deleted from both ARB files and the generated localizations are regenerated with `flutter gen-l10n`.

## Risks / Trade-offs

- [Deselecting a dose by tapping it again is less discoverable than an explicit chip] → It is the standard Material choice-chip behavior, and the default preselection still follows the last intake, so users who log without a dose rarely need to deselect at all.
- [The four-letter "All" chip next to "Week"/"Month"/"Year"] → Shorter than before; no layout risk.
- [A longer "Единица измерения" label] → It is a floating `TextFormField` label on a full-width field, so it fits on phone widths.
