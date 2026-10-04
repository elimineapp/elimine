# Design

## Context

The bottom navigation is a `StatefulShellRoute.indexedStack` with two branches (`/` and `/analytics`). `/settings` is a top-level route pushed from a gear `IconButton` in the Home app bar, so it covers the navigation bar and gets an automatic back arrow. The Settings screen is a self-contained `Scaffold` (app bar with a progress indicator, a `ListView`, snackbars via `ScaffoldMessenger`).

## Goals / Non-Goals

**Goals:**
- Settings as the third tab with its own preserved state, like Home and Analytics.

**Non-Goals:**
- Changing the content of the Settings screen.
- Changing system back behavior on non-Home tabs; Settings behaves the same as Analytics does today.

## Decisions

**Order: Settings · Home · Analytics.** The more often a destination is used, the easier it is to reach with the thumb.
- Home goes in the middle: it is the start destination and the daily two-tap path, and the middle is within easy reach of either thumb.
- Analytics goes on the right: used less than Home but more than Settings, it gets the slot a right thumb reaches easily.
- Settings goes on the left: it is the rarest destination, and the left edge is the hardest to reach one-handed.
- Alternative: Home · Analytics · Settings (the conventional order). Rejected: it puts the most used destination in the hardest slot.
- Alternative: Analytics · Home · Settings. Rejected: it puts Analytics, used more often than Settings, in the hardest slot.

**The app still opens on Home.** The router's initial location stays `/`, which now matches the middle branch; `StatefulShellRoute` selects that branch without an explicit index.

**Settings becomes a shell branch at `/settings`.** The path stays the same, so `context.go('/settings')` and any existing references keep working. The route is moved from the top level into a third `StatefulShellBranch`; the top-level route is removed so there is one way in.

**Icon and label.** `Icons.settings_outlined` / `Icons.settings` for the unselected/selected states, matching the outlined/filled pair used by the other destinations. The label reuses `settingsTitle`; no new strings.

**No back arrow.** As the root of its branch, the Settings `AppBar` has nothing to pop and shows no back arrow without any code change.

## Risks / Trade-offs

- [Settings snackbars now appear inside the shell] → They show above the navigation bar, as snackbars on Home and Analytics already do; no change needed.
- [Muscle memory for the gear on Home and for Analytics as the second tab] → One-time relearning; acceptable for a young app.
- [Settings is not in its conventional last slot] → With three labelled destinations it is visible at a glance.
- [The order favors right-handed use] → Home, the destination that matters most, stays in the middle for either hand.
