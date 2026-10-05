# Proposal

## Why

Moving around the app feels abrupt in the places used most. The three tabs switch with no transition at all. The edit screen fades in over a substance sheet that does not react, and going back removes it in about a tenth of a second. Saving a new substance, archiving and deleting swap whole screens without visual continuity. The sheet itself already moves well. Because the rest does not, the app feels unfinished.

## What Changes

- Switching between "Settings", "Home" and "Analytics" uses a fade through: the old tab fades out, the new one fades in and settles from a slight scale. Each tab still keeps its state.
- The substance sheet keeps its look and gestures. It becomes a page that can share elements with the screens around it.
- The substance badge is a shared element across the main path:
  - from the Home tile into the sheet;
  - from the sheet into the edit screen;
  - and back.
- Opening the edit screen grows the sheet to full screen while its content cross-fades into the form. Back reverses it into the sheet.
- The "New substance" row expands into the new substance screen. After saving, the form shrinks into the new substance's collapsed sheet.
- Archiving or deleting from the edit screen shrinks the editor back into the sheet, then the sheet closes onto Home.
- The archive screen opens and closes with a shared-axis (depth) transition.
- The new and edit screens show the substance badge in their header, live with the chosen color and icon.
- On Android, the system back gesture plays these transitions backward as the finger moves, and cancelling the gesture restores the screen.
- With the system "Remove animations" setting on, screen changes happen without movement.
- All transitions use one set of durations and easing curves. The analytics period paging moves onto that set.

Non-goals:
- Animating items as they appear in or leave lists: Home tiles, "Recent", History and the archive list. This includes the tile disappearing after archiving or deleting. That is a separate, follow-up change.
- Changing dialogs, snackbars or the "Edit entry" sheet.

## Capabilities

### New Capabilities
- `motion`: how the app moves between screens. Covers tab switching, the transitions along the Home → substance sheet → edit screen path, the new substance and archive transitions, the back gesture, and the reduced-motion behavior.

### Modified Capabilities
- `substances`: the new and edit screens show the substance badge in their header, reflecting the chosen color and icon.

## Impact

- Code:
  - `lib/app/sheet_page.dart`: the sheet becomes a custom `PageRoute` that keeps today's sheet behavior.
  - `lib/app/router.dart`: custom pages for the edit, new substance and archive routes.
  - `lib/app/shell.dart` and the shell route: an animated branch container instead of the plain indexed stack.
  - New `lib/app/motion/`: motion tokens and the transition pages.
  - `lib/features/home/home_screen.dart`, `lib/features/substance/substance_screen.dart`, `lib/features/substance/substance_form_screen.dart`: shared-element tags, transition origins, the badge in the form header, the archive and delete exit sequence.
  - `lib/features/analytics/period_bar.dart`: its duration and curve come from the motion tokens.
  - `android/app/src/main/AndroidManifest.xml`: opt in to the predictive back gesture.
- Tests: `navigation_test`, `substance_form_test` and `substance_screen_test` will need updating where they depend on route types or timing. Transitions get their own widget tests.
- No new dependencies, no database or backup change.
