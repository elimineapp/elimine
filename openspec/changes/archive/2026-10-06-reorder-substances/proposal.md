# Proposal

## Why

Home lists substances "in the user's substance order", but that order is only ever the order of creation: there is no way to change it. A substance created early and taken rarely can sit above the one taken every week. Users need to put the substances they reach for most where their thumb expects them.

## What Changes

- Long-pressing a substance tile on Home lifts it, and dragging moves it to another place in the list. Tapping a tile still opens the substance screen.
- The new order is saved on the device as soon as the tile is dropped, and Home keeps it after restarts, new substances, archiving and restoring.
- The "New substance" row stays last and cannot be moved or dropped below.
- Screen reader users can move a tile with "Move up" and "Move down" actions.
- Only manual order. Automatic sort modes (by last intake, by name, by frequency) are out of scope, because a list that rearranges itself after every intake breaks the position users rely on.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `home`: adds reordering substance tiles by drag, its persistence and its accessibility actions.

## Impact

- Home screen: the substance list becomes reorderable, with a lifted look while dragging.
- Substance service: a new operation that moves one substance to a new place and renumbers the stored order.
- Localization: none of its own; the move actions use Flutter's localized labels.
- No database migration: substances already store their order, backups already export it, and restoring from the archive already returns a substance to its place.
- Analytics is unaffected: its chips and stacks stay in palette order.
