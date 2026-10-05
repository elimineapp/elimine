# Design

## Context

- `substances.sortOrder` already exists. `SubstanceService.create` appends at `max + 1`, and Home and the archive screen order by `sortOrder, id`. Archived substances keep their `sortOrder`, and `restore` only clears `archivedAt`.
- Backups export substances in that order, and import appends them in the same order. No schema or backup format change is needed.
- Home is one `CustomScrollView`: a `SliverList.separated` of `_SubstanceTile`s followed by `_NewSubstanceTile`, then "Recent" and the archive row. Tiles are fed by `substancesProvider`, a drift stream.
- A tile's icon is a `Hero` (`SubstanceIconHero`) that flies into the substance screen. No widget in the app uses long-press yet.

## Goals / Non-Goals

**Goals:**
- Drag reordering inside the existing Home scroll view, without a separate "edit order" mode.
- No visible snap-back between dropping a tile and the database stream catching up.
- Archived substances keep their place among their neighbors.

**Non-Goals:**
- Automatic sort modes or a sort setting.
- Reordering on the archive screen. It keeps following the same stored order.
- Reordering doses.

## Decisions

### `SliverReorderableList` with delayed drag start

Replace the substance `SliverList.separated` with a `SliverReorderableList` (using `onReorderItem`, whose index already accounts for the removed item) and wrap each tile in `ReorderableDelayedDragStartListener`, so a long press starts the drag and a tap reaches the tile's `InkWell`. The list sits in the existing `CustomScrollView`, so the scroll view auto-scrolls while dragging near its edge and "Recent" stays below.

- The "New substance" row moves out of the reorderable list into its own `SliverToBoxAdapter` directly after it. The list can then only drop tiles above it, with no special index handling.
- The 8 px gaps move from the separator into each item's bottom padding, because `SliverReorderableList` has no separator builder. The dragged item then carries its gap with it.
- `proxyDecorator` gives the lifted tile a Material elevation and a slight scale, animated with the drag's own animation. Picking a tile up triggers `HapticFeedback.mediumImpact()`, as the substance screen already does.

Alternatives: `ReorderableListView` is a whole scroll view and cannot share one with "Recent" without nesting scrollables. A third-party grid or reorder package adds a dependency for a single list. An "Edit order" mode costs extra taps and an extra header action, which the Home header does not allow.

### Optimistic local order

`HomeScreen` keeps the order it shows in local state. `onReorder` reorders that list at once and then calls the service. When the stream emits, the local list is replaced by the stream's list. Without this, the tile would jump back to its old slot for a frame or two until drift's query re-runs.

### `SubstanceService.move(id, beforeId)` renumbers everything

The service takes the moved id and the id of the active substance it now sits before (`null` for the end). In one transaction it reads all substances, archived ones included, ordered by `sortOrder, id`, removes the moved one, inserts it before `beforeId` (or after the last active substance when `beforeId` is null), and writes `sortOrder = 0..n-1`.

- Because archived substances are part of the renumbered list, they keep their neighbors, and "Restore" still puts them back in place.
- Renumbering also removes any duplicate `sortOrder` values left by older data, so `id` stops deciding the order.
- An n of a few dozen rows makes the full rewrite cheap.

Alternatives: fractional or gap-based orders avoid rewriting rows but need rebalancing, and save nothing at this size. Swapping only the two adjacent values works only for one-step moves.

### Accessibility actions from the list itself

`SliverReorderableList` already gives each item the custom semantics actions "Move up", "Move down", "Move to the start" and "Move to the end", leaving out the ones that do not apply at the ends of the list, and routes them through `onReorderItem`, like a drop. Their labels come from Flutter's widgets localizations, which include Russian. The app adds no actions or strings of its own.

Alternative: our own `Semantics` actions and ARB strings would duplicate the built-in ones and give a screen reader every action twice.

## Risks / Trade-offs

- [The `Hero` inside the drag proxy] The proxy lives in an overlay, outside the route's subtree, so it should not clash with the tile's own hero. → A widget test opens the substance screen right after a drag to make sure the icon still flies.
- [Long press conflicts with scrolling] A slow scroll that starts on a tile could start a drag. → The default delayed listener only starts after the long-press timeout without movement. Check on a device.
- [Stream emits during a drag] The stream re-emits on any change to substances or intakes, for example the save of the previous drop arriving while the next drag has already started. → Ignore stream updates while a drag is active and apply the latest one when it ends.

## Migration Plan

None: the column and its values already exist. The first move rewrites `sortOrder` for all substances.
