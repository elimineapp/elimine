# Proposal

## Why

The Home tiles look flat and cramped. Every tile has the same grey background, so substances differ only by a 40 px badge. Each tile has an empty middle. Long names get cut after about ten characters. Tapping a tile replaces Home with a full substance screen just to press "Log", so the two-tap flow feels heavier than it is. Editing an intake already uses a bottom sheet, and logging should feel the same.

## What Changes

- Home shows substances as full-width cards in a single column instead of a two-column grid. Each card:
  - is tinted with the substance's color and shows the icon on a filled circle;
  - shows the name on up to two lines and the familiar "250 mg · 12 days ago" line;
  - has a strip of 12 marks, one per calendar week, filled when the substance was taken that week.
- The "New" tile becomes a "New substance" row at the end of the list.
- The substance screen becomes a sheet that rises over Home:
  - Collapsed, it shows only the logging block (time, dose, "Log") and a "Chart and history" row with the edge of the chart.
  - Dragged up, or with that row tapped, it expands to fill the screen and becomes the full substance screen with the chart and history.
  - It nudges upward on opening until the user has expanded it once, so the gesture can be discovered.
- "Log" in the collapsed sheet closes it and shows the snackbar on Home. In the expanded sheet the user stays, as on today's substance screen.
- Dragging down collapses an expanded sheet and closes a collapsed one. Tapping outside the sheet or pressing system back closes it.
- After a new substance is saved, Home opens with that substance's sheet collapsed, ready for the first intake.

## Capabilities

### New Capabilities
- `substance-screen`: how the substance screen is presented. It is a sheet over Home with a collapsed and an expanded state. The capability covers the gestures and controls that move between those states, the expand hint, and how the sheet closes.

### Modified Capabilities
- `home`: substance tiles become tinted full-width cards with a weekly intake strip; "New" becomes a "New substance" row.
- `intake-logging`: what happens after "Log" depends on whether the substance sheet is collapsed or expanded.
- `navigation`: the substance screen opens as a sheet over Home instead of a separate screen. Back closes it.
- `substances`: after creation the app returns to Home with the new substance's sheet open.

## Impact

- Code:
  - `lib/features/home/home_screen.dart`: cards and the "New substance" row.
  - `lib/features/substance/substance_screen.dart`: becomes the sheet.
  - `lib/app/router.dart`: `/substance/:id` becomes a sheet page above Home.
  - `lib/features/substance/substance_form_screen.dart`: after-creation navigation.
  - `lib/services/settings_service.dart`: a device flag for the expand hint.
  - New week-strip bucketing on top of `watchDailyTotals`.
  - Localization: "Chart and history", "Collapse", "New substance".
- Tests: `home_screen_test`, `substance_screen_test`, `navigation_test` and `substance_form_test` need updating.
- No database schema change. The expand-hint flag is a row in the existing `settings` table and is not part of backups.
