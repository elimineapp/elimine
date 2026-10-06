# Tasks

## 1. Theme generator

- [x] 1.1 Add `design/theme/gen.py`, which builds the light and dark "Ink" schemes with `materialyoucolor` (2021 spec, fidelity variant, palettes from design.md) and writes `lib/app/theme.dart` with `inkLight` and `inkDark` `ColorScheme` constants covering every non-deprecated field from `primary` to `surfaceTint`, under a header saying the file is generated and naming the script. Add `design/theme/README.md` with the setup and the command to run it. Verify that running it as documented produces the `surface`, `surfaceContainer`, `primary`, `primaryContainer` and `secondaryContainer` values in design.md's table
- [x] 1.2 Generate `lib/app/theme.dart` with the script and run `dart format` on it. Verify `flutter analyze` is clean and a second run of the script leaves the file unchanged

## 2. Apply the theme

- [x] 2.1 In `ElimineApp`, replace `colorSchemeSeed` with `ThemeData(colorScheme: inkLight)` and `ThemeData(colorScheme: inkDark)`. Add `test/theme_test.dart`, which pumps `ElimineApp` with an initial light and then dark preference. Verify the tests check that `primaryContainer` is `#1B2638` in both themes, that `surface`, the `surfaceContainer*` roles and `outlineVariant` have no visible tint (RGB channels within 16 of each other), and that the existing tests still pass

## 3. Night icon

- [x] 3.1 In `design/icon/source/gen.py`, make the background a flat `#1B2638` with the existing radial highlight, and make `#3A5FBD` the dark leaf's color. Write `ic_launcher_background.xml` as a solid ink path plus a radial-gradient highlight path matching the SVG (center 20%/15%, radius 80%, 18% white to transparent). Leave the leaf paths, scales and the monochrome layer as they are. Verify by running the script and opening `out/source/icon-rounded-preview.svg`: both leaves show on the ink background
- [x] 3.2 Copy the outputs into `android/app/src/main/res/` and `design/icon/` as `design/icon/README.md` describes. Verify with `git diff --stat` that only the expected icon files changed and that `ic_launcher_monochrome.xml` is unchanged
- [x] 3.3 Update the description in `design/icon/README.md` ("Two leaves, light and blue, on ink") and verify it matches the new master SVG

## 4. Verification

- [x] 4.1 Run `task check` (format, analyzer, tests) and verify it passes
- [x] 4.2 On a device, build a release signed with `android/key.properties` and install it over the existing app with `adb install -r`. In both themes, check that Home, a substance screen, Analytics, Settings, the log and edit sheets and the undo snackbar have no green tint, that text buttons can be told apart from body text, and that substance colors look as before. Check the launcher icon with circle and squircle masks, on a dark wallpaper and with themed icons on
