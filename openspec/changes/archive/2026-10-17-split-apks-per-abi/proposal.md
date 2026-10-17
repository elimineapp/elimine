# Proposal

## Why

The F-Droid submission has to follow fdroiddata's template for Flutter apps and its inclusion checklist. Three points of our current setup differ from them: we ship one universal APK of about 64 MB where the checklist asks for per-ABI APKs when that makes them much smaller (about 25 MB for arm64-v8a); the Dart packages live in a pub cache outside the project, where F-Droid's scanner does not look; and the recipe pins its own Flutter version, so every Flutter upgrade would need a merge request to fdroiddata. Because the release build must stay byte-identical to F-Droid's, these have to change in our build too, and the submission moves to the next release, 0.3.1.

## What Changes

- **BREAKING**: Each release publishes three APKs, one per processor architecture (`elimine-X.Y.Z-armeabi-v7a.apk`, `elimine-X.Y.Z-arm64-v8a.apk`, `elimine-X.Y.Z-x86_64.apk`), instead of one universal `elimine-X.Y.Z.apk`. A user picks the one for their phone; the README says which.
- Each APK's version code is 1000 × the architecture's number (1, 2 and 4, as Flutter assigns them) plus the release's build number, so 0.3.1 has 1003, 2003 and 4003. Every one of them is above the 2 of the universal 0.3.0, so existing installs update in place.
- The release build puts the pub cache inside the project, as F-Droid's recipe does so its scanner covers the Dart packages, and builds each architecture the way the recipe does.
- The F-Droid recipe gets one build block per architecture, takes the Flutter version from our CI configuration instead of naming it, and gains the author name and e-mail. The check that compared the two Flutter versions goes away.
- The F-Droid check workflow compares all three APKs.
- 0.3.1 is released with only these changes and submitted to fdroiddata.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `releases`: a GitHub release offers one APK per processor architecture; the version code includes the architecture; F-Droid publishes the same per-architecture APKs.

## Impact

- `tool/release_build.sh`: per-ABI builds, pub cache in the project.
- `.github/workflows/release.yml`: signs, verifies and attaches three APKs.
- `.github/workflows/fdroid-check.yml`: builds and compares three APKs; no Flutter version check.
- `fdroid/com.elimine.elimine.yml`, `fdroid/README.md`: per-ABI build blocks, Flutter version from `.github/actions/setup/action.yml`, `--enforce-lockfile`, author fields.
- `README.md` (which APK to download, `apksigner` example), `CONTRIBUTING.md` (release and Flutter upgrade notes).
- Local `task build:apk` and `flutter run` keep building a universal APK for development.
- No app behavior, data or backup changes.
