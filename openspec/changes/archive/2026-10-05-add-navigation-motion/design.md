# Design

## Context

- **Tabs.** The router uses `StatefulShellRoute.indexedStack`. The three branch navigators sit in an `IndexedStack`, so switching tabs is instant. `AppShell` calls `goBranch(i, initialLocation: i == currentIndex)`.
- **Sheet route.** The substance sheet is a `SheetPage` that builds a `ModalBottomSheetRoute`, which is a `PopupRoute`. Its body is a `DraggableScrollableSheet` with `minChildSize: 0`. The modal bottom sheet closes the route when the sheet reaches its minimum extent: it listens for `DraggableScrollableNotification.shouldCloseOnMinExtent`. The collapsed size is measured from the logging block after the first frame, and until then a default fraction of 0.6 is used.
- **Other routes.** Edit, new substance and archive use plain `builder`s, so they get `MaterialPage`. Flutter 3.47 on Android resolves that to `PredictiveBackPageTransitionsBuilder`, which falls back to `FadeForwardsPageTransitionsBuilder`. Its delegated "previous page" animation only reaches a previous `PageRoute`, so the sheet under the edit screen never moves. Its reverse fades out within the first 25% of 450 ms.
- **Heroes.** Hero flights only run between two `PageRoute`s. A Hero inside a nested navigator, such as Home inside its branch, takes part only if its route is the top `PageRoute` of that navigator. go_router already wraps navigators in a `HeroControllerScope`.
- **Predictive back.** `TransitionRoute` already implements `PredictiveBackRoute` and drives its controller from the gesture progress, so any custom route scrubs for free. The manifest does not set `android:enableOnBackInvokedCallback`. With `targetSdk` 36 the gesture is on by default only on Android 16.
- **Existing motion.** Analytics paging uses `periodPageDuration` (280 ms) and `periodPageCurve` (`easeOutCubic`) from `period_bar.dart`.
- **Form header.** The form has no badge today; its `AppBar` shows only the title.

## Goals / Non-Goals

**Goals:**
- Implement every transition as a route or container widget, so screens do not know how they are animated. The only exception is shared-element tags and transition origins.
- Keep the routes and URLs of the router unchanged, and keep `context.push`/`go`/`pop` as the way to navigate.
- No new package. The `animations` package was considered and is not needed (see the decisions below).

**Non-Goals:**
- List item animations (follow-up change).
- Custom transitions for dialogs, snackbars and the "Edit entry" sheet.
- An iOS-specific motion set. The same transitions run on every platform for now.

## Decisions

### Motion tokens in one place
`lib/app/motion/motion.dart` defines the durations and curves. All transitions read them, and `Motion.reducedOf(context)` reports reduced motion from `MediaQuery.disableAnimationsOf`.

| Token | Value | Used by |
|---|---|---|
| `short` | 200 ms | fades, reduced-motion fades |
| `medium` | 300 ms | fade through (tabs), shared axis (archive), analytics paging |
| `long` | 400 ms | container transform (sheet → edit, row → new, form → sheet) |
| `emphasized` | `Easing.emphasizedDecelerate` in, `Easing.emphasizedAccelerate` out | container transform, sheet slide |
| `standard` | `Easing.standard` | fade through, shared axis, paging |

`periodPageDuration` and `periodPageCurve` become aliases of `medium`/`standard`, so analytics paging goes from 280 ms to 300 ms.

With reduced motion, every route uses a plain cross-fade and the tab container cross-fades without scaling. Flutter already runs animation controllers 20 times faster in this mode, so these fades are near-instant. Heroes are disabled by `SubstanceIconHero`, which wraps the badge's `Hero` in `HeroMode(enabled: !reduced)`.

### Tabs: an animated branch container that keeps state
The shell becomes `StatefulShellRoute` with a `navigatorContainerBuilder` that returns a `FadeThroughBranches` widget:
- A `Stack` holds every branch navigator.
- When `currentIndex` changes, one `AnimationController` (`medium`, `standard`) plays the fade through:
  - the outgoing branch fades out over `Interval(0, 0.35)`;
  - the incoming one fades in over `Interval(0.35, 1)` and scales from 0.92 to 1.
- Branches that are not involved are `Offstage`, with `TickerMode(enabled: false)`, `ExcludeFocus` and `HeroMode(enabled: false)`. This matches what `IndexedStack` gave and keeps a hidden tab's heroes out of flights.
- Only the incoming branch receives pointer events during the transition.

`AppShell` keeps its `NavigationBar` and does not take part in the transition.

- *Alternative: `PageTransitionSwitcher` from `animations`.* Rejected: it rebuilds or disposes the outgoing child, which loses branch state (spec: navigation "Switching tabs keeps state").
- *Alternative: a `PageView` with a horizontal slide.* Rejected in exploration: the user chose fade through for tabs.

### The sheet becomes a `PageRoute`
`SheetPage.createRoute` returns a new `SheetRoute extends PageRoute` with:
- `opaque: false`, `barrierDismissible: true` and the bottom sheet's `modalBarrierColor`;
- `useSafeArea` behavior: top safe area applied, as today.

It reproduces what `ModalBottomSheetRoute` provided:
- a `NotificationListener<DraggableScrollableNotification>` pops the route when `extent == minExtent && shouldCloseOnMinExtent`;
- the entrance is a slide up from the bottom (`emphasized`, `medium`).

The page fills the screen, with the sheet aligned to the bottom. The entrance translates it by the sheet's last measured height. A page the size of the sheet would move the origin that Hero flights compute their destination from.

The entrance waits for the sheet to know its size:
- `didPush` holds the controller at 0;
- `SubstanceScreen` calls `SheetRoute.revealOf(context)` once its collapsed height is measured, with a 150 ms fallback timer.

So that the header, and the icon flying into it, exist from the first frame, the sheet takes the substance from Home's already loaded list until its own query answers. It also keeps the last substance it saw, so it still renders while closing after a deletion.

Being a `PageRoute` gives two things:
- Heroes fly into and out of it.
- It receives the `secondaryAnimation` of the edit route above it. It uses that to fade its content out during `Interval(0, 0.3)` while the edit route's container grows from the sheet's bounds.

`canTransitionTo` returns true only for `ContainerTransformRoute`, so other routes above it, such as the "Edit entry" sheet, leave it still.

- *Alternative: keep `ModalBottomSheetRoute` and fake the transform inside the edit route with a snapshot of the sheet.* Rejected: no Hero, and the snapshot goes stale when the sheet content changes.

### One container transform route for three transitions
`ContainerTransformPage` / `ContainerTransformRoute` (a `PageRoute`) takes a `TransitionOrigin`, which bundles:
- a `GlobalKey` of the origin widget;
- its corner radius;
- its surface color.

On every forward or reverse start, the route resolves the origin's current global rect from the key. It then animates:
- a clip rect from the origin rect to the full screen, and the corner radius to 0;
- the surface color from the origin color to the destination `surface`;
- the destination content fading in over `Interval(0.3, 1)`.

It is used by:
- **Sheet → edit.** The origin is the sheet's `Material` surface. Because the origin is resolved again on reverse, back lands on the sheet's current size, whether that is collapsed, expanded or re-measured after saving changed the dose chips.
- **"New substance" row → new form.** The origin is the row, with radius 20 and a transparent surface, so the surface color lerps from Home's background.

The origin is passed with `context.push(path, extra: origin)`. When `extra` is missing, for example after a deep link or state restoration, the route falls back to the shared-axis transition.

- *Alternative: `OpenContainer` from `animations`.* Rejected: it pushes an imperative route of its own and cannot be a go_router page or carry our URLs.

### Form → collapsed sheet after saving
`_save` for a new substance first switches the form's badge Hero tag to the new id. It then calls `pushReplacement('/substance/$newId', extra: SheetEntrance.fromFullScreen)`. In that mode the `SheetRoute` entrance does two things:
- Instead of sliding up, it clips its surface from the full screen down to its own collapsed bounds. The top inset animates from 0 to the sheet's top, with the radius going from 0 to 28.
- Its content fades in over `Interval(0.3, 1)`.

Meanwhile the replaced `ContainerTransformRoute` receives the `secondaryAnimation` and fades the form out. The badge flies from the form header into the sheet header, and Home appears under the shrinking surface with the barrier fading in.

### Leaving with the substance: two steps
`_archive` and `_delete` stop calling `context.go('/')` directly. Instead they:
1. Pop the edit route (the reverse container transform into the sheet) and wait until its animation is `dismissed`.
2. Call `context.go('/')`, which pops the sheet with its normal slide down.
3. Show the snackbar on the root messenger only then. `confirmAndDeleteSubstance` gets a `report` parameter, defaulting to `true`. The edit screen passes `false` and shows the same snackbar itself after step 2. The archive screen keeps today's behavior.

If the widget is unmounted between steps, for example on rotation or process death, step 2 still runs from a captured `GoRouter`. When the edit screen has nothing below it to return to, as when opened from a link, step 1 is skipped.

### Archive: shared axis Z
`SharedAxisPage` is a `PageRoute`. The incoming page fades in over `Interval(0.3, 1)` and scales 0.8 → 1. It sets `delegatedTransition`, so the shell page below scales 1 → 1.1 and fades out over `Interval(0, 0.3)`. Duration and curve are `medium` and `standard`. This is also the fallback for `ContainerTransformRoute` without an origin.

### Shared substance icon
`substanceIconTag(id)` is the Hero tag on:
- the Home tile badge (not the "Recent" badges, which would duplicate the tag on one route);
- the sheet header badge;
- the form header badge.

The new form uses a placeholder tag until it is saved. All three badges are `SubstanceBadge(filled: true)` at the same size, so the default shuttle needs no custom `flightShuttleBuilder`. On a pop from a form with an unsaved color change, the default shuttle shows the destination badge, and the colors snap at the end. This is accepted.

### Form header badge
The form `AppBar` gets a `leading`-adjacent `SubstanceBadge(filled: true)` in the title row. It is built from `_color`/`_icon` state, so it updates as soon as a color or icon is picked.

### Predictive back
`android:enableOnBackInvokedCallback="true"` is added to `<application>`. `TransitionRoute` can be driven by the gesture, but in Flutter only Material's `PredictiveBackPageTransitionsBuilder` listens for it. So each custom route wraps its transitions in a `PredictiveBack` widget. It is a `WidgetsBindingObserver` that forwards start, progress, commit and cancel to its route while that route is current, which scrubs each route's own transition backward. Tabs have no back, so the branch container is unaffected.

## Risks / Trade-offs

- [The sheet's collapsed size is measured after the first frame, so a Hero flight computed at push time lands where the sheet would be at 0.6, then the sheet jumps] → The entrance is held at 0 until the size is measured (see "The sheet becomes a `PageRoute`"). Hero flights also retarget when their destination moves.
- [Hero setup briefly sets the new route offstage, which makes its proxied animation report "completed"] → `SheetRoute` listens to its controller, not to `animation`, to know when its entrance is over.
- [Reimplementing `ModalBottomSheetRoute` can drift from today's behavior: barrier color, semantics label, drag-to-dismiss, keyboard insets] → `navigation_test` and `substance_screen_test` already cover open, close by drag, barrier tap and back. Add a check of the barrier color and the `scrimLabel` semantics.
- [`go('/')` from deep inside (edit over sheet) and the two-step exit could race with a user tap during the first step] → Absorb pointers on the edit route while the exit sequence runs.
- [Widget tests that assume a `ModalBottomSheetRoute`, or a timing settled within a fixed number of pumps] → Tests use `pumpAndSettle`. Update type checks to `SheetRoute`. Add transition tests that pump to the midpoint and assert opacity, scale and clip values.
- [Fade through over heavy tabs (charts) may drop frames on low-end devices] → Wrap each branch in a `RepaintBoundary` during the transition. Check in profile mode on a device.
- [Enabling `enableOnBackInvokedCallback` changes back-to-home behavior on Android 13–15] → This is the platform's intended behavior. Verify that the system back-to-home animation shows from Home.

## Migration Plan

Nothing to migrate: no data or settings change. Rollback is a code revert. The manifest flag can be reverted independently if predictive back misbehaves.
