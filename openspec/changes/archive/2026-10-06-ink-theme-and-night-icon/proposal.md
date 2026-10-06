# Proposal

## Why

The app's colors come from one muted green seed (`#3F6E5A`), and Material 3 tints every surface with it: backgrounds, cards and the navigation bar are grey-green, and the dark theme looks swampy. The accent also sits close to the "aqua" and "green" substance colors, so a button or selection can read as one more substance. The launcher icon has the same problem: its glyph is already paper and ink, but its mint-to-blue gradient makes it read as green.

## What Changes

- The theme moves to "Ink": near-neutral surfaces (warm paper in the light theme, graphite with a hint of ink in the dark one) and a single accent taken from the icon's ink color `#1B2638`. In the dark theme the accent is a light steel blue.
- Substance colors do not change. They become the only vivid colors on screen.
- The launcher icon moves to "Night": a flat ink background with the existing soft highlight. The light leaf stays paper `#F7F6F1`, the dark leaf turns blue `#3A5FBD` so it shows on the ink background. The glyph's shapes and placement do not change.
- The themed (monochrome) icon on Android 13+ does not change.
- The icon generator and every icon resource it produces are regenerated: adaptive layers, legacy and round icons, the Play Store image and the kept iOS icon.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `appearance`: a new requirement for the app's color palette: neutral surfaces, an ink accent, and substance colors as the only vivid colors.
- `branding`: the adaptive launcher icon's background becomes ink instead of a green-to-blue gradient, and its dark leaf becomes blue.

## Impact

- `lib/app/app.dart`: `colorSchemeSeed` is replaced by explicit light and dark color schemes, defined in a new theme file under `lib/app/`.
- A small generator for the color schemes is kept under `design/`, next to the icon generator, so the values can be reproduced and adjusted.
- `design/icon/source/gen.py`, `design/icon/source/*.svg`, `design/icon/README.md`, the Play Store and iOS images.
- `android/app/src/main/res/`: `drawable/ic_launcher_background.xml`, `drawable/ic_launcher_foreground.xml` and the `mipmap-*` PNGs.
- No data, database or backup changes. Screens keep reading colors from the theme, so their code does not change.
