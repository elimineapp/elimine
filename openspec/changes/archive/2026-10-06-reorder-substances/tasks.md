# Tasks

## 1. Stored order

- [x] 1.1 Add `SubstanceService.move(id, beforeId)`: in one transaction, renumber all substances (archived included) by `sortOrder, id` with the moved one placed before `beforeId`, or after the last active substance when `beforeId` is null. Verify with tests in `test/database_test.dart` for moving up, moving down, moving to the end, and duplicate `sortOrder` values being resolved
- [x] 1.2 Test that an archived substance keeps its neighbors: archive the middle of three, move the last to the top, restore, and expect "Ibuprofen", "Coffee", "Melatonin" from `watchSubstancesWithLast`
- [x] 1.3 Test that a substance created after a move is last, and that a backup exported after a move imports into an empty database in the same order (`test/backup_service_test.dart`)

## 2. Drag on Home

- [x] 2.1 Replace the substance `SliverList.separated` in `HomeScreen` with a `SliverReorderableList` of tiles wrapped in `ReorderableDelayedDragStartListener`, with the 8 px gap as item padding, and move "New substance" into its own sliver right after it. Verify the existing `test/home_screen_test.dart` and `test/motion_test.dart` still pass
- [x] 2.2 Keep the shown order in local state: reorder it at once in `onReorder`, call `move`, take the stream's list when it emits, and hold stream updates while a drag is active. Verify with a widget test that long-presses and drags the third tile above the first and finds the new order right after the drop and after the stream settles
- [x] 2.3 Add the `proxyDecorator` (elevation and slight scale) and haptic feedback on pickup. Verify with a widget test that a tap on a tile still opens the substance screen and that opening it right after a drag throws no duplicate hero error
- [x] 2.4 Verify with a widget test that dragging a tile below "New substance" drops it just above that row

## 3. Accessibility

- [x] 3.1 Rely on the move actions `SliverReorderableList` adds to each item (labels from Flutter's widgets localizations, Russian included) instead of custom ARB strings and `Semantics`
- [x] 3.2 Verify with a widget test that the first tile offers "Move down" but not "Move up", the last tile the opposite, and that performing "Move down" on the first tile moves it and saves the order

## 4. Verification

- [x] 4.1 Run `task check` (format, analyzer, tests) and verify it passes
- [x] 4.2 On a device or emulator: reorder by long-press and drag with enough substances to scroll, check that a slow scroll starting on a tile does not start a drag, that the order survives an app restart, that archiving and restoring keeps the place, and that TalkBack offers "Move up" and "Move down"
