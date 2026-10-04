# Design

## Context

- `SubstanceScreen` is a full `Scaffold` page at `/substance/:id`. The route is a top-level `GoRoute` outside the shell, so it covers the bottom navigation. The screen holds the logging block, the `SubstanceChart` and a `SliverList` of `IntakeTile`s. Its edit screen is the child route `/substance/:id/edit`.
- Only two places navigate to `/substance/:id`:
  - a tap on a Home tile (`context.push`);
  - the new-substance form after saving (`context.pushReplacement`).

  Archiving and deleting from the edit screen call `context.go('/')`.
- The "Edit entry" sheet (`showEditIntakeSheet`) already uses `showModalBottomSheet` on the root navigator. It shows its snackbar on the screen underneath after it closes.
- `watchDailyTotals` returns per-local-day counts per substance. `weekStartProvider` gives the chosen first weekday. `SettingsService` stores device preferences as key/value rows in the `settings` table, which backups do not include.
- The agreed look comes from the "Elimine substance tiles" design canvas (the prototype artboard, `layout: list`).

## Goals / Non-Goals

**Goals:**
- Keep `/substance/:id` as the one way to open a substance, so the form, deep links and `go('/')` keep working. Only change how that page is presented.
- Use one scrollable for the whole sheet, so pulling the sheet and scrolling the history are the same gesture.

**Non-Goals:**
- Redesigning the dose chart, the history rows or the "Edit entry" sheet.
- Changing "Recent" on Home or the archive screen.
- Adding a new database query or table for the week strip.

## Decisions

### The substance route becomes a modal sheet page
`/substance/:id` stays a route, and its `pageBuilder` returns a custom `Page` whose `createRoute` builds a `ModalBottomSheetRoute`:
- scroll controlled;
- drag enabled;
- use safe area;
- a barrier that dismisses it on tap.

The route moves under `/` as the sub-route `substance/:id` with `parentNavigatorKey: rootNavigatorKey`, so Home is always below it, even on `go`. `/substance/new` and the `edit` child keep their current form. The edit screen is pushed above the sheet, so back from it returns to the sheet. `context.go('/')` after archive or delete pops both pages, which covers "Leaving with the substance".

- *Alternative: an imperative `showModalBottomSheet` from the Home tile.* Simpler for the tap, but after-creation would need a second mechanism. Nothing would close the sheet on `go('/')`, because pageless routes attached to the shell page survive it. The route also could not be deep-linked or tested through the router.
- *Alternative: navigating to a full page once the sheet crosses a drag threshold.* Rejected: the switch shows as a jump, and there would be two widgets for one screen.

### One DraggableScrollableSheet with two snap sizes
The sheet body is a `DraggableScrollableSheet`:
- `expand: false`;
- `snap: true`;
- `snapSizes: [collapsed, 1.0]`;
- `initialChildSize` and `minChildSize` = `collapsed`.

Its scroll controller drives a `CustomScrollView` that holds the header, the logging block, the "Chart and history" row, the chart and the history. Dragging down from `minChildSize` lets the modal route's own drag dismiss it.

`collapsed` is not a fixed fraction. It is the measured height up to the bottom of the "Chart and history" row plus a fixed peek of the chart (about 56 dp), divided by the available height. The logging block is measured with a `GlobalKey` after the first layout. Until then a conservative default fraction is used. This keeps the chart's edge visible on every screen size and font scale.

The expanded state is detected from `DraggableScrollableController.size >= 0.99`. It switches the header from "handle + title + last intake" to "Collapse + title". "Collapse" and the "Chart and history" tap call `controller.animateTo`. Collapsing also scrolls the content back to the top, so the collapsed view always shows the logging block.

- *Alternative: a hand-rolled `AnimatedPositioned` sheet like the prototype.* Rejected: it would have to reimplement nested scrolling, flings and the modal barrier.

### Snackbars follow the state
- **Collapsed "Log":** pop the route and show the snackbar through the messenger captured before popping (Home's root `ScaffoldMessenger`), like `showEditIntakeSheet` does.
- **Expanded "Log":** stay. The sheet wraps its content in its own `ScaffoldMessenger` + transparent `Scaffold`, so the snackbar, and swipe-to-delete snackbars from `IntakeTile`, appear above the sheet instead of behind the modal barrier.

### Expand hint stored as a device setting
`SettingsService` gets a `sheetExpanded` key with a watch and a set method, in the same style as `weekStart`. When the sheet opens with the flag unset, it waits for the opening animation and then animates up by about 28 dp and back. The flag is set the first time the controller reaches the expanded size, whether by drag or by tap. It lives in `settings`, so backups leave it out by construction.

### Week strip computed from daily totals
A pure function `weekMarks(List<DailyTotal> totals, DateTime today, int firstWeekday)` returns `Map<String, List<int>>`: the number of intakes in each of the 12 weeks per substance, oldest first. It sits next to `AnalyticsPeriod`, reuses its week-start arithmetic and compares the `day` strings, which are already local days.

A Home provider watches `dailyTotalsProvider` with `since` set to the start of the 12th week minus one day of margin, plus `weekStartProvider`. It then calls `weekMarks`. One query serves every tile, and no schema or SQL change is needed.

- *Alternative: a dedicated SQL query grouping by week.* Rejected: week start is a user setting, and SQLite week grouping would duplicate the Dart period logic that analytics already tests.

### Tile visuals
The tile is a `Material` with radius 20 and the substance color at 14% alpha (22% in dark), with an `InkWell`. Inside is a `Row`:
- a filled 40 dp badge, with the icon in white on light and in the surface color on dark;
- a `Column` with the name (`titleMedium`, `maxLines: 2`, ellipsis), the last-intake line (`bodyMedium`, `onSurfaceVariant`, one line) and the strip (12 rounded 6 dp bars, `outlineVariant` when empty, the substance color at 75% for one intake, 87.5% for two and 100% for three or more).

`SubstanceBadge` gains a `filled` option instead of a second badge widget. The "New substance" row is an outlined, dashed-looking `OutlinedButton.icon` spanning the width. A plain outline is acceptable if a dashed border needs a custom painter.

## Risks / Trade-offs

- [The horizontal swipe of the dose chart inside a vertically draggable sheet] → The gesture arena separates horizontal and vertical drags. Verify on a device that a slightly diagonal swipe on the chart still pages and does not move the sheet.
- [The measured collapsed height changes after the first frame, so the sheet may jump on open] → Measure the logging block offstage on the first frame, or start with the default fraction and only correct it before the opening animation ends. Check this at large font scales.
- [The edit-intake sheet opening over an expanded substance sheet] → Both are modal routes on the root navigator, so they stack correctly. Verify the visuals and that "Delete" and "Undo" snackbars land on the substance sheet's messenger.
- [Existing widget tests pump `SubstanceScreen` directly as `home:`] → Keep the sheet content as a widget that can be pumped on its own (expanded) for the logging and history tests. Add router-level tests for open, expand, collapse and close.
- [Cards are taller than grid tiles, so fewer substances fit above the fold] → Accepted. The user chose the list for long names and readability. The order is user-defined, so frequent substances can stay on top.

## Migration Plan

Nothing to migrate: no schema change, and the new settings key defaults to "not expanded yet", so existing users see the hint once. Rollback is a code revert.
