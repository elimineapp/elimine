# Tasks

## 1. Motion tokens

- [x] 1.1 Add `lib/app/motion/motion.dart` with the `short`/`medium`/`long` durations, the `emphasized` and `standard` curves, and `Motion.reducedOf(context)` reading `MediaQuery.disableAnimationsOf`. Verify with a unit/widget test in `test/motion_test.dart`: `reduced` follows `MediaQueryData(disableAnimations: true)`, and every duration is ≤ 500 ms.
- [x] 1.2 Make `periodPageDuration` and `periodPageCurve` in `period_bar.dart` read `medium` and `standard`. Verify that `test/analytics_screen_test.dart` and `test/substance_chart_test.dart` still pass.

## 2. Tab fade through

- [x] 2.1 Switch the shell to `StatefulShellRoute` with a `navigatorContainerBuilder` returning a new `FadeThroughBranches` widget:
  - a `Stack` of branch navigators;
  - the outgoing branch fades over `Interval(0, 0.35)`, the incoming one fades over `Interval(0.35, 1)` and scales 0.92 → 1;
  - inactive branches are `Offstage` with `TickerMode` off, `ExcludeFocus` and `HeroMode` off;
  - pointer events go to the incoming branch only.

  Verify widget tests in `test/navigation_test.dart`:
  - halfway through Home → Analytics, Analytics has opacity in (0, 1) and scale < 1;
  - after settling, only Analytics is onstage;
  - tapping the selected "Home" leaves Home at opacity 1 and scale 1 mid-way;
  - the existing "Year range kept" test passes.
- [x] 2.2 Under reduced motion, cross-fade branches over `short` without scaling. Verify a widget test with `disableAnimations: true`: the incoming branch has scale 1 at the midpoint.

## 3. Sheet as a page route

- [x] 3.1 Replace `ModalBottomSheetRoute` in `sheet_page.dart` with a `SheetRoute extends PageRoute`. It must provide:
  - non-opaque, with a dismissible barrier using the bottom sheet's `modalBarrierColor` and `scrimLabel`;
  - a top safe area;
  - a slide-up entrance (`medium`, `emphasized`);
  - a `DraggableScrollableNotification` listener that pops at `minExtent` when `shouldCloseOnMinExtent`.

  Verify the existing `test/navigation_test.dart` and `test/substance_screen_test.dart` sheet tests pass: open, drag closed, barrier tap, back, expand, collapse and the log snackbars. Add a test that the barrier has the `scrimLabel` semantics label.
- [x] 3.2 Make sure the collapsed size is known before the entrance is visible: measure the logging block offstage on the first frame, or hold the entrance at 0 until `_collapsedHeight` is set. Verify a widget test: the sheet size at the first visible entrance frame already equals the measured collapsed size, so it does not jump later. Also test at a 1.3 text scale. At 2.0 the sheet header overflows its fixed height; that is an existing layout issue outside this change.
- [x] 3.3 Under reduced motion, the sheet enters and leaves with a `short` fade instead of a slide. Verify a widget test with `disableAnimations: true`: the sheet's vertical offset at the midpoint of the entrance is 0.

## 4. Shared substance icon and form header

- [x] 4.1 Show a filled `SubstanceBadge` next to the title on the new and edit screens, built from the form's current color and icon. Verify tests in `test/substance_form_test.dart`:
  - the edit screen of a green cup "Coffee" shows that badge;
  - picking red changes the badge before saving;
  - the new screen shows the default color.
- [x] 4.2 Add `substanceIconTag(id)` Heroes on:
  - the Home tile badge (not the "Recent" badges);
  - the sheet header badge;
  - the form header badge, with a placeholder tag for the unsaved new form.

  Verify a widget test in `test/navigation_test.dart`: halfway through opening "Coffee" from Home, exactly one badge with its tag is in the Hero overlay. Also verify the app raises no duplicate-tag assertion when "Coffee" is both a tile and in "Recent".

## 5. Container transform: sheet ↔ edit, row ↔ new

- [x] 5.1 Add `ContainerTransformPage`/`ContainerTransformRoute` taking a `TransitionOrigin` (`GlobalKey`, radius, color). It must:
  - resolve the origin rect at each forward and reverse start;
  - lerp the clip rect, radius and surface color (`long`, `emphasized`);
  - fade content in over `Interval(0.3, 1)`;
  - fade its content out on `secondaryAnimation`;
  - fall back to the shared-axis transition (5.4) without an origin.

  Verify widget tests in `test/motion_test.dart` on a minimal two-route app:
  - at the midpoint the clip rect lies strictly between the origin and the full screen;
  - the reverse targets the origin's new rect after it moved;
  - without an origin, no clip is applied.
- [x] 5.2 Route `/substance/:id/edit` through `ContainerTransformPage`. The sheet's settings action passes the sheet surface as the origin. `SheetRoute` fades its content out on `secondaryAnimation` only when the next route is a `ContainerTransformRoute`. Verify tests in `test/navigation_test.dart`:
  - halfway through opening the edit screen, its clip top is between the sheet top and 0, and the sheet content opacity is < 1;
  - after back, the sheet is collapsed again;
  - opened from the expanded sheet and saved, the sheet is still expanded;
  - opening "Edit entry" over the sheet leaves the sheet content at opacity 1.
- [x] 5.3 Route `/substance/new` through `ContainerTransformPage` with the "New substance" row as the origin (radius 20). Verify a test: halfway through opening, the clip rect contains the row's rect and is smaller than the screen. After back, Home shows the row.
- [x] 5.4 Add `SharedAxisPage` and route `/archive` through it:
  - incoming page: fade over `Interval(0.3, 1)` and scale 0.8 → 1;
  - shell page below: `delegatedTransition` that scales it 1 → 1.1 and fades it over `Interval(0, 0.3)`.

  Verify a test in `test/archive_test.dart`: halfway through opening, the archive screen's scale is in (0.8, 1). After back, Home is shown and the archive test cases still pass.
- [x] 5.5 Under reduced motion, container transform and shared axis become a `short` cross-fade, and the substance icon Heroes are disabled (`SubstanceIconHero`). Verify a widget test with `disableAnimations: true`: opening the edit screen applies no clip and no Hero flight.

## 6. New substance → sheet, archive and delete exits

- [x] 6.1 After saving a new substance, switch the badge tag to the new id, then `pushReplacement` the sheet with `SheetEntrance.fromFullScreen`. In that mode the sheet's surface shrinks from full screen to its collapsed bounds, with its content fading in over `Interval(0.3, 1)`, while the form fades out. Verify a test in `test/substance_form_test.dart`:
  - halfway through, the sheet's clip top is between 0 and its collapsed top;
  - after settling, the "Tea" sheet is collapsed over Home and the form is gone.
- [x] 6.2 Replace the direct `go('/')` in `_archive` and `_delete` with the two-step exit: pop the edit route and wait for it to be dismissed, then `go('/')`. Absorb pointers on the edit route meanwhile. Add a `report` parameter to `confirmAndDeleteSubstance`; the edit screen passes `false` and shows the snackbar after step 2. Verify tests in `test/substance_form_test.dart`:
  - after "Archive", at the end of the first step the edit route is gone and the sheet is still shown;
  - after settling, Home has no sheet and no tile;
  - after "Delete", the snackbar naming the substance appears only after the sheet has closed;
  - the archive screen's delete still shows its snackbar immediately.

## 7. Predictive back

- [x] 7.1 Add `android:enableOnBackInvokedCallback="true"` to `<application>` in `AndroidManifest.xml`. Verify `flutter build apk --debug` succeeds. Wrap the custom routes' transitions in a `PredictiveBack` observer that forwards the gesture to the route. Verify a widget test in `test/archive_test.dart` that sends a back gesture over `flutter/backgesture` (start, progress 0.5, cancel) on the archive screen: the archive scales down mid-gesture, then is still on top with its scale back at 1.

## 8. Verification

- [x] 8.1 Manual check on a device or emulator (Android 14+), in light and dark theme:
  - switch between all three tabs and check that Analytics keeps its range;
  - open a substance from Home and watch the icon fly into the sheet;
  - open the edit screen from the collapsed and from the expanded sheet, then go back with the button and with the back gesture, holding halfway and cancelling;
  - create a substance and watch the form shrink into its sheet;
  - archive and delete from the edit screen;
  - open and leave the archive;
  - repeat with "Remove animations" on;
  - check the tab switch on Analytics with a full year for dropped frames in profile mode.
- [x] 8.2 Verify `openspec validate add-navigation-motion --strict` passes.
- [x] 8.3 Run `task check` and verify formatting, analyzer and tests pass.
