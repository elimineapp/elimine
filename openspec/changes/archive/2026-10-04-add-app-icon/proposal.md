# Proposal

## Why

The app still ships Flutter's default launcher icon, so it is hard to find on the home screen and looks unfinished. A finished icon set already exists (two leaves, light and dark, on a green-to-blue gradient), with Android adaptive layers as vector drawables, a monochrome layer for themed icons, legacy square and round icons, a Play Store image, an iOS icon and the script that generates them all.

## What Changes

- Replace the default launcher icon with the Elimine icon as an Android adaptive icon: background and foreground layers, so every launcher mask (circle, rounded square, squircle) shows it correctly.
- Add a monochrome layer so the icon follows the system theme when the user enables themed icons (Android 13+).
- Provide legacy square and round icons for Android versions without adaptive icons.
- Keep the icon sources (master SVG, generator script, the 512 px store image, the iOS icon set) in the repository so the launcher resources can be regenerated and future targets (iOS, store listings) reuse the same artwork.

## Capabilities

### New Capabilities
- `branding`: how the app presents itself to the system: its name and launcher icon across launcher shapes, themed icons and older Android versions.

### Modified Capabilities

None.

## Impact

- `android/app/src/main/res/`: vector drawable layers, adaptive icon definitions for Android 8+, legacy `ic_launcher` and `ic_launcher_round` PNGs replacing the template icons.
- `android/app/src/main/AndroidManifest.xml`: a `roundIcon` reference.
- New `design/icon/` directory with the icon sources.
- No Dart code, dependency, database or UI changes.
