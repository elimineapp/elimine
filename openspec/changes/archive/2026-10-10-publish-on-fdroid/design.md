# Design

## Context

- Releases are built by `.github/workflows/release.yml` on a tag created by release-please: one universal APK, signed with the release key, its certificate checked against `.github/release-cert.sha256`. Flutter is pinned to 3.47.5 in `.github/actions/setup/action.yml`; Java is Temurin 17.
- `pubspec.yaml` has `version: 0.2.0` without a build number. `android/app/build.gradle.kts` computes `versionCode = major * 1_000_000 + minor * 1_000 + patch` (0.2.0 is 2000). The release-process design chose this over `+N` because it was unclear how release-please's Dart updater treats a build number.
- The release workflow checks `grep -qx "version: $VERSION" pubspec.yaml`, which fails once the line has a build number.
- Storage is drift on `package:sqlite3` 3.5.2. Its build hook downloads a prebuilt `libsqlite3.so` per ABI from the sqlite3.dart GitHub releases (checked by sha256) and bundles it. `sqlite3_flutter_libs` is EOL and no longer involved.
- The build does not set `dependenciesInfo`, so AGP adds its encrypted dependency metadata block to the APK.
- F-Droid builds each version from a recipe in `fdroiddata` on its own build server, scans the source for binaries, and with `Binaries` and `AllowedAPKSigningKeys` set, publishes the upstream APK if it matches its own build apart from the signature. `checkupdates` finds new versions by tag and reads the version name and code with regular expressions over files in the checkout. It cannot compute a code from three numbers.
- The owner's phone runs a release-signed 0.2.0 build (version code 2000) with the only real data.

## Goals / Non-Goals

**Goals:**
- The GitHub APK and the F-Droid APK are the same file.
- No step of a release build downloads a binary.
- New versions reach F-Droid without a merge request per release.
- Screenshots can be retaken with the same data after UI changes.

**Non-Goals:**
- Google Play, RuStore, IzzyOnDroid, an AAB or per-ABI APKs.
- Per-version changelogs in the store listing (see Decisions).
- Russian screenshots: the Russian listing uses the English images.
- Removing or rewriting the 0.1.0 and 0.2.0 GitHub releases.

## Decisions

### The reproducibility check comes first and gates the F-Droid parts
Before the metadata and the fdroiddata merge request, two release builds of the same commit, made after the SQLite and `dependenciesInfo` changes, are compared:
1. two local builds in different checkout directories;
2. a local build against one made inside the fdroidserver build container (`registry.gitlab.com/fdroid/fdroidserver:buildserver`), which matches F-Droid's paths and toolchain, using the draft recipe.

Unsigned APKs are compared with `apksigcopier compare` (what F-Droid runs), and differences are examined with `diffoscope`. Typical sources are the build path or build ID embedded in `libapp.so` and in NDK-compiled libraries, and differing JDK or NDK versions. Result of step 1: two clean builds at the same path are byte-identical, while builds at different paths differ only in `libapp.so` and `libdartjni.so`. `libapp.so` embeds the absolute `file://` URI of the generated `.dart_tool/flutter_build/dart_plugin_registrant.dart`, which also changes the snapshot layout, and `libdartjni.so` (from `package:jni`, used by `path_provider_android`) gets a different build ID. Flutter has no option to remap that path, so the release workflow builds in F-Droid's build directory, `/home/vagrant/build/com.elimine.elimine`, instead of the runner's workspace. SQLite compiled by the hook is identical across paths.

Result of step 2, against `fdroid build` in the `buildserver-trixie` image: the Dart snapshot, `classes.dex`, resources and `libflutter.so` match, and the JDK (17 or 21) makes no difference. The native libraries built by hooks did not: the GitHub runner's `ANDROID_NDK_HOME` points at NDK r27, which Flutter hands to build hooks, so `libsqlite3.so` came from clang 18 instead of r28c's clang 19, and the build ID of `libdartjni.so` depends on the source paths in the pub cache. `tool/release_build.sh` therefore mirrors F-Droid's layout: the project in `/home/vagrant/build/com.elimine.elimine`, `PUB_CACHE=/home/vagrant/.pub-cache`, the SDK at `/opt/android-sdk` and NDK r28c as `ANDROID_NDK_HOME`. `fdroid build` removes signing configs from `build.gradle.kts` by itself, so the recipe needs no `sed` for that.

If the differences cannot be removed, the work stops at that point and the owner chooses between an F-Droid-signed build (the `Releases on F-Droid` requirement then changes: no shared signature, and switching sources needs a reinstall) and postponing F-Droid. The version code, SQLite and `dependenciesInfo` changes are useful either way and stay.

### SQLite is compiled from a downloaded, pinned amalgamation
`pubspec.yaml` gets:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: source
      path: third_party/sqlite/sqlite3.c
```

`third_party/sqlite/` holds a `VERSION` file and a `README.md`, not the source itself. `VERSION` names the SQLite version the prebuilt binaries of `package:sqlite3` 3.5.2 use (3.53.4), the URL of its official amalgamation on sqlite.org, the SHA3-256 that sqlite.org publishes for that archive and the SHA-256 of the `sqlite3.c` inside it. `tool/fetch_sqlite.sh` downloads the archive, checks both hashes and extracts `sqlite3.c` next to `VERSION`, where it is ignored by git; it does nothing when the right file is already there. `task deps` runs it before `flutter pub get`, so local builds, CI and the release workflow (all through `task deps`) get it, and the F-Droid recipe runs it in `prebuild`. The package's default compile options stay on, so the library behaves like the prebuilt one. The hook compiles it with the NDK that Flutter already pins.

Why downloaded: the owner prefers not to keep third-party source in the repository (about 2.4 MB of git history per SQLite update). The pinned hashes make the download as fixed as a committed file, so our CI and F-Droid still compile the same bytes.

Alternatives: committing `sqlite3.c` (simplest and needs no network, but grows the history); a git submodule (there is no official git repository of the amalgamation); `source: system` (Android's own SQLite is not part of the NDK's stable API); going back to `sqlite3_flutter_libs` (EOL).

### Dependency metadata off
`android { dependenciesInfo { includeInApk = false; includeInBundle = false } }` in `build.gradle.kts`. The block helps only Google Play, which is not a target.

### Version code is the build number in pubspec.yaml
`pubspec.yaml` gets `version: 0.2.0+1`, and `build.gradle.kts` uses `flutter.versionCode` and `flutter.versionName` as the Flutter template does. The formula and its comment go away.

release-please's Dart updater (`src/updaters/dart/pubspec-yaml.ts`) keeps a numeric build number and raises it by one when it bumps the version, so the next release becomes `0.3.0+2`, then `+3` and so on. This settles the uncertainty the release-process design avoided.

Starting point: 1 for the current version, so the first release with this scheme gets 2. 0 is avoided because Android treats version codes as positive and some tools reject 0. This restarts the sequence below 2000, which the owner accepted (see Migration Plan).

The release workflow's version check becomes a match on `^version: $VERSION\+[0-9]+$`, and the README, CONTRIBUTING and the comment in `pubspec.yaml` stop saying there is no build number.

F-Droid reads both values with the usual Flutter pattern:

```
UpdateCheckMode: Tags ^v[0-9]+\.[0-9]+\.[0-9]+$
UpdateCheckData: pubspec.yaml|version:\s.+\+(\d+)|.|version:\s(.+)\+
AutoUpdateMode: Version
```

Alternatives: keeping the formula (F-Droid cannot compute it); keeping it and continuing the build number from 2000 (rejected by the owner in favour of starting over).

### F-Droid recipe
Submitted to `fdroiddata` as `metadata/com.elimine.elimine.yml`, roughly:

```yaml
Categories: [Habit Tracker, Health Manager]
License: GPL-3.0-or-later
SourceCode: https://github.com/elimineapp/elimine
IssueTracker: https://github.com/elimineapp/elimine/issues
Changelog: https://github.com/elimineapp/elimine/blob/HEAD/CHANGELOG.md
RepoType: git
Repo: https://github.com/elimineapp/elimine.git
Binaries: https://github.com/elimineapp/elimine/releases/download/v%v/elimine-%v.apk
Builds:
  - versionName: 0.3.0
    versionCode: 2
    commit: v0.3.0
    output: build/app/outputs/flutter-apk/app-release.apk
    srclibs: [flutter@3.47.5]
    prebuild: tool/fetch_sqlite.sh
    build:
      - $$flutter$$/bin/flutter config --no-analytics
      - $$flutter$$/bin/flutter build apk --release
AllowedAPKSigningKeys: f6c0b3635b4298f3c825b22aaaf6f716fe9e464ccfcf8320276c478622f251d0
AutoUpdateMode: Version
UpdateCheckMode: Tags ^v[0-9]+\.[0-9]+\.[0-9]+$
UpdateCheckData: pubspec.yaml|version:\s.+\+(\d+)|.|version:\s(.+)\+
CurrentVersion: 0.3.0
CurrentVersionCode: 2
```

The recipe is kept in `fdroid/com.elimine.elimine.yml` (see below); this is what it settled on after the reproducibility check and `fdroid lint`. Name, summary, description and images come from our fastlane directory, so the recipe has none of its own.

Upgrading Flutter later also means updating `srclibs` in the recipe through a merge request to fdroiddata, because auto-update copies the previous build block. CONTRIBUTING notes this next to the pinned version.

### The recipe lives in the repository and is checked after every release
`fdroid/com.elimine.elimine.yml` is our copy of the fdroiddata recipe with a placeholder version, and `fdroid/README.md` says to carry every change over to fdroiddata. `.github/workflows/fdroid-check.yml` takes a ref, fills in its version, code and commit, and runs `fdroid build` in the `buildserver-trixie` image the way fdroiddata's CI does (including `fdroid lint`). For a release tag it compares the result with the published `elimine-X.Y.Z.apk`, so it checks exactly what F-Droid will check; for a branch it compares with a fresh `tool/release_build.sh` build. It also fails when the Flutter version in the recipe differs from the one CI pins. `release.yml` calls it after attaching the APK, and it can be run by hand.

Why: F-Droid quietly skips versions whose build does not match, and the causes are outside this repository as often as inside it (a runner image's NDK, a Flutter upgrade without a recipe update, fdroidserver changes). A check right after the release tells us within minutes instead of days. It costs a few CI minutes per release.

Alternatives: dropping the check after the first submission (cheaper, but mismatches show up only as a missing F-Droid update); running it on every push to main (more runs than needed, since only tags are published).

### Changelog stays on GitHub
F-Droid shows "What's new" from `fastlane/.../changelogs/<versionCode>.txt` read from the tagged commit. release-please writes the changelog in the release commit itself, so a file keyed by the new version code would have to be produced inside the release pull request, which needs a custom step in release-please's flow. The recipe's `Changelog` link to `CHANGELOG.md` gives F-Droid users the same information. Per-version files can be added later without changing anything else.

### Store listing layout

```
fastlane/metadata/android/
  en-US/
    title.txt                Elimine
    short_description.txt    at most 80 characters
    full_description.txt     what it does, what it does not do (no network, accounts, tracking)
    images/icon.png          512 px, a copy of design/icon/android/play-store-512.png
    images/phoneScreenshots/1_home.png ... 4_analytics.png   (light)
  ru-RU/
    title.txt, short_description.txt, full_description.txt
docs/screenshots/dark/1_home.png ... 4_analytics.png
```

Only the light set goes into `phoneScreenshots`, because F-Droid shows every file there. The dark set lives in `docs/screenshots/dark/`. The full description follows the README's "What it does" and "What it does not do", so the two are updated together.

### Screenshots from a demo backup
A Dart script, `tool/demo_backup.dart`, writes a version 1 backup file (`docs/backup-format.md`) with five substances and about nine months of history, so the year view of Analytics is filled, dated relative to the moment it runs (or to a local time given as an argument):

| Substance | Unit, icon, color | Pattern |
| --- | --- | --- |
| Coffee | cup, coffee, orange | almost daily, doses 1 and 2, last one two hours ago |
| Melatonin | mg, moon, violet | in runs of several nights |
| Ibuprofen | mg, pill, blue | rare, some intakes without a dose |
| Alcohol | ml, drink, magenta | weekends |
| Nicotine | no unit, smoke, green | once or twice a day until three months ago, nothing since |

Ids are UUIDv5 from fixed names, so the data is the same every time except for the dates. The pattern uses a fixed random seed.

Capture runs on the `elimine_pixel8` emulator, never on the phone. A Task target `screenshots:prepare` builds and installs the app on the emulator, pushes the demo file to Downloads, and turns on the system UI demo mode (clock 9:41, full battery and signal, no notifications). When the emulator image allows root, `prepare` also sets the emulator's clock to 9:41 today and generates the data for that moment, so times in the app match the status bar. After importing the file through Settings → Import, `screenshots:capture NAME=...` saves `adb exec-out screencap -p` into the right directory. Navigating between shots is manual: four shots per theme do not justify scripting taps.

Shots, in both themes: Home; a collapsed Coffee sheet with its dose buttons (logging); the expanded Coffee screen with the month chart; Analytics for the year with all substances.

Alternatives: `integration_test` screenshots (no status bar, a new test target to maintain for four images); real data (personal).

### README
A row of four screenshots under the introduction, each a `<picture>` with a `prefers-color-scheme: dark` source from `docs/screenshots/dark/` and the light image from the fastlane directory as the default, at a fixed width of 200 px. Install lists F-Droid first, with its badge, and GitHub Releases second. The feature list adds editing and deleting an intake, reordering substances on Home, and choosing the language and theme. A short note under Install says that 0.1.0 and 0.2.0 cannot be updated in place to later versions.

## Risks / Trade-offs

- [Flutter or NDK output is not reproducible across build paths] → found by the first check before any submission; mitigations are build flags for path remapping or running our release build at F-Droid's path in a container. Failing that, the owner decides (see the first decision).
- [Compiling SQLite in the hook changes the library compared with the prebuilt one] → same version and same default options; `task check` exercises the database, and the manual check on the emulator covers import, logging and analytics.
- [F-Droid reviewers object to a download in `prebuild`, or sqlite.org moves the archive] → the download is a source archive checked against the hash sqlite.org publishes, which fdroiddata accepts in practice; if not, `sqlite3.c` can be committed after all with no other change.
- [The sqlite3 package changes the hook's user defines in a later version] → the version is locked in `pubspec.lock`; `third_party/sqlite/README.md` says to recheck the hook docs when upgrading.
- [The F-Droid review takes weeks or asks for changes] → nothing in our release flow waits for it. GitHub releases continue as before.
- [The restart of the version code strands 0.1.0 and 0.2.0 installs] → there is one such install, migrated by backup and restore; the README note covers anyone else.
- [A Flutter upgrade without a recipe update breaks reproducibility for that release] → CONTRIBUTING ties the two; F-Droid then skips that version until the recipe is fixed.

## Migration Plan

1. Merge the build changes (SQLite, `dependenciesInfo`, version code) and the listing. The release PR then proposes `0.3.0+2`.
2. Before installing any build with the new version code on the phone: Export on the phone, import the file on the emulator and compare the number of substances and intakes with the phone. Then, only on the owner's explicit go-ahead at that moment, uninstall the app on the phone, install the 0.3.0 release APK, import the backup, and set the language, theme and first day of the week again.
3. Release 0.3.0 through the usual release PR. Check that the GitHub APK has version code 2 and the published certificate.
4. Open the merge request to `fdroiddata` with the recipe for 0.3.0.

Rollback: the build changes can be reverted like any commit, but the version code cannot go back to the 2000 range without stranding installs again, so the restart is final once 0.3.0 is out.

## Open Questions

- Whether to add a note to the 0.1.0 and 0.2.0 release notes on GitHub as well as the README. It does not affect the build or the listing.
