# Proposal

## Why

The fact of an intake is valuable even without its dose: the dose may be forgotten, or the history may come from another tracker that never recorded doses. Today every intake must have a dose and every substance a unit, so such history cannot be kept. This also has to land before data export, so the export format reflects the final data model.

## What Changes

- An intake may have no dose. Existing intakes keep their doses; the database migrates in place.
- The substance screen gets a "No dose" chip, first in the dose row. It is preselected when the last intake had no dose, or when the substance has neither intakes nor doses. The "Log" button is always enabled.
- A substance's unit becomes optional. Without a unit, doses show as plain numbers.
- Intakes without a dose read "No dose" in history; a Home tile whose last intake had no dose shows only when it happened.
- The substance dose chart keeps summing doses and marks days (or months) that also had intakes without a dose with a dot; the tooltip lists them. When the selected range has intakes but none with a dose, the chart counts intakes instead.
- Cross-substance analytics already counts intakes and is unchanged.
- Importing data from other apps is not part of this change; it builds on the export and import work.

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `intake-logging`: dose selection gains "No dose"; logging no longer requires a dose; history shows intakes without a dose.
- `substances`: the unit is no longer required.
- `substance-chart`: intakes without a dose are marked on the dose chart; a range without any dose shows intake counts; titles without a unit.
- `home`: tile text for a last intake without a dose.

## Impact

- Database: `intakes.amount` becomes nullable (schema version 1 → 2, the first migration), with migration tests.
- Daily totals query: also returns how many intakes had a dose.
- Substance screen, substance form, substance chart, shared bar chart (marker support), Home tile, intake list tile, formatting helpers.
- Localization: new English and Russian strings.
- Tests: migration, service, analytics and widget tests.
