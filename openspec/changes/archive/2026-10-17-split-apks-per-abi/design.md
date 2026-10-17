# Design

## Context

- `tool/release_build.sh` builds one universal APK in F-Droid's build directory with `PUB_CACHE=/home/vagrant/.pub-cache`, the SDK at `/opt/android-sdk` and NDK r28c; `release.yml` signs it, checks the certificate and attaches `elimine-X.Y.Z.apk`; `fdroid-check.yml` builds the tag with `fdroid build` from `fdroid/com.elimine.elimine.yml` and compares. 0.3.0 passed that check.
- fdroiddata's Flutter template (`templates/build-flutter.yml`) puts `PUB_CACHE` inside the project so the scanner covers the Dart packages, runs `flutter pub get --enforce-lockfile` in `prebuild`, deletes `.pub-cache` from the scan with `scandelete`, checks out the Flutter version named in the upstream repository, and builds one ABI per build block with `--split-per-abi --target-platform`.
- With `--split-per-abi`, the Flutter Gradle plugin sets each APK's version code to `1000 × abi + versionCode` with `armeabi-v7a` = 1, `arm64-v8a` = 2, `x86_64` = 4 (`FlutterPluginConstants.ABI_VERSION`).
- fdroidserver's auto-update computes one version code per `VercodeOperation` entry and copies that many of the last build blocks as templates (`checkupdates.py`). A build's `binary` field overrides the app's `Binaries` and has `%v` and `%c` replaced (`build.py`).
- The maintainer's phone runs the universal 0.3.0 (version code 2), signed with the release key.

## Goals / Non-Goals

**Goals:**
- Our three APKs and F-Droid's three are identical apart from the signature, and the F-Droid check proves it for every release.
- The recipe follows fdroiddata's template closely enough that review is about the app, not the recipe.
- A Flutter upgrade needs no change in fdroiddata.

**Non-Goals:**
- An x86 (32-bit) APK: Flutter no longer builds it.
- A universal APK on GitHub (see below).
- App bundles (AAB).

## Decisions

### Three APKs, no universal one
GitHub releases attach `elimine-X.Y.Z-armeabi-v7a.apk`, `-arm64-v8a.apk` and `-x86_64.apk`. A universal APK is not published alongside: it would have version code `N` while the per-ABI ones have `1000 × abi + N`, so a phone that took a per-ABI APK from F-Droid could never update from it, which breaks switching sources. The README's Install section names `arm64-v8a` for most phones and `armeabi-v7a` for old 32-bit ones; `x86_64` is for emulators and a few tablets.

Alternatives: keep only the universal APK and explain in the merge request (the checklist asks for splits when they are much smaller, which they are); publish all four (blocks updates as above).

### Version codes are Flutter's
No custom scheme: Flutter's override gives 1003/2003/4003 for build number 3. The recipe's `VercodeOperation` mirrors it with `1000 + %c`, `2000 + %c`, `4000 + %c`, and its build blocks are ordered by version code (v7a, arm64, x86_64), because auto-update copies the last three blocks in order. The build number keeps growing by one per release, so the codes have room for 999 releases per architecture.

### Each ABI is built separately, the same way in both places
`tool/release_build.sh` runs `flutter build apk --release --split-per-abi --target-platform android-arm` (then `android-arm64`, `android-x64`) one after another in the same project directory, exactly like the three recipe blocks. Whether one build of all three gives the same bytes as three single-ABI builds is not known, and checking it is not worth a risk to reproducibility. The extra time is small because Gradle and the Dart front end reuse their outputs.

### Pub cache inside the project
Both the release build and the recipe use `PUB_CACHE=<project>/.pub-cache` and `flutter pub get --enforce-lockfile`. The path ends up in the build ID of `libdartjni.so`, so it has to be the same in both; the project path already is. `.pub-cache/` is already ignored by git, and `release_build.sh` does not copy one from the workspace. The recipe lists `.pub-cache` under `scandelete`, as the template does.

### The recipe reads the Flutter version from our CI
The recipe uses the `flutter@stable` srclib and, in `prebuild`, checks out the version from `.github/actions/setup/action.yml`, which stays the only place the version is pinned. The F-Droid check's Flutter version comparison and the CONTRIBUTING rule about updating fdroiddata on upgrades are removed.

### Recipe details
- One block per ABI with its own `binary: https://github.com/elimineapp/elimine/releases/download/v%v/elimine-%v-<abi>.apk`; no app-level `Binaries`.
- `AuthorName: Elimine`, `AuthorEmail: elimine.app@gmail.com`.
- `commit` is the full hash of the tag, as the checklist requires; `fdroid-check.yml` fills it in from the ref it checks.
- `prebuild` per block: Flutter checkout, `tool/fetch_sqlite.sh`, `flutter config --no-analytics`, `flutter pub get --enforce-lockfile`.
- `rm` from the template is not needed: the repository has no `ios`, `linux`, `macos`, `web` or `windows` directories.

### F-Droid check per ABI
`fdroid-check.yml` runs the F-Droid build as a matrix over the three ABIs (each job builds one block, as F-Droid's server does) and the compare job checks each APK against the published one (release mode) or our release build (branch mode).

### Release 0.3.1
The commit is `build:`, which release-please does not release on its own, so it carries a `Release-As: 0.3.1` footer. It is not marked `!`: installed apps update in place, and only the download file names change, which the release notes and README cover.

## Risks / Trade-offs

- [A single-ABI build differs from what F-Droid builds for that block] → both run the same command in the same directory with the same environment, and the F-Droid check compares all three before the submission.
- [Users download the wrong APK and Android refuses it] → the README names the right one for almost every phone; Android shows "App not installed" rather than doing anything harmful, and the F-Droid client picks automatically.
- [Release time triples] → only the APK job and the F-Droid check grow, by a few minutes each.
- [Links to `elimine-X.Y.Z.apk` from before 0.3.1 point at a name that no longer exists for new versions] → old releases keep their files; README and release notes show the new names.

## Migration Plan

1. Merge with `Release-As: 0.3.1`; the release PR proposes `0.3.1+3`.
2. Merge the release PR; the release workflow attaches three APKs and the F-Droid check passes for all three.
3. On the phone, `adb install -r` the release-signed `arm64-v8a` APK of 0.3.1 (version code 2003 over 2); no uninstall.
4. Fill `fdroid/com.elimine.elimine.yml` for 0.3.1 and open the fdroiddata merge request after the owner approves its text.

Rollback: revert the commit; the next release is universal again with version code `N + 1`, which is below the per-ABI codes, so per-ABI installs would need a reinstall. Treat the split as final once 0.3.1 is out.
