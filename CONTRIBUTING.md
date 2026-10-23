# Contributing

## Language

Everything in the repository is written in English: code, comments, specs, docs and commit messages. The Russian UI translation lives in `lib/l10n/app_ru.arb`.

## Specs

Requirements live in `openspec/specs/`. Behavior changes start as an OpenSpec change in `openspec/changes/` and are archived into the specs when done.

## Commits

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<optional scope>): <summary>

<optional body>
```

- Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style`, `revert`.
- Scope is optional and names the area, e.g. `analytics`, `db`, `l10n`.
- The summary is imperative and lowercase, with no trailing period: `feat(analytics): add busiest weekday metric`.
- A breaking change adds `!` after the type or scope and a `BREAKING CHANGE:` footer.

Run `task check` before committing.

## Releases

Releases are cut by [release-please](https://github.com/googleapis/release-please) from the commit messages, so the commit type decides what users see:

- `feat` raises the minor version, `fix` and `perf` the patch version (before 1.0.0, a breaking change raises the minor version too).
- `feat`, `fix`, `perf` and `revert` appear in `CHANGELOG.md`; `docs`, `test`, `ci`, `build`, `chore`, `refactor` and `style` do not.

Every push to `main` updates an open release pull request with the next version and its changelog entry. Merging it tags `vX.Y.Z` and creates the GitHub release; the release workflow then runs the full check on the tag, builds one APK per ABI, signs them with the release key, verifies their certificate against `.github/release-cert.sha256` and attaches `elimine-X.Y.Z-armeabi-v7a.apk`, `elimine-X.Y.Z-arm64-v8a.apk` and `elimine-X.Y.Z-x86_64.apk`. If that build fails after the release exists, fix the cause and run the Release workflow manually with the tag to attach the APKs.

Do not edit the version in `pubspec.yaml` by hand. It reads `X.Y.Z+N`: release-please sets `X.Y.Z` and raises the build number `N` by one with every release. Each APK's Android version code is `1000 × ABI + N` (1 for `armeabi-v7a`, 2 for `arm64-v8a`, 4 for `x86_64`), as Flutter sets it with `--split-per-abi`, and F-Droid reads both values from this line.

F-Droid builds each release tag itself and publishes our APKs only if its builds are identical apart from the signature. Its recipe is kept in `fdroid/com.elimine.elimine.yml` (see `fdroid/README.md`), and after every release the F-Droid check workflow builds the tag the same way and compares. The Flutter version is pinned only in `.github/actions/setup/action.yml`, and the recipe reads it from there. Any other change to the recipe has to be made in [fdroiddata](https://gitlab.com/fdroid/fdroiddata) too, through a merge request.

The release key is never committed. Locally, release builds use it only when `android/key.properties` points at it; otherwise they are signed with the debug key.

## Dependencies

Dependabot (`.github/dependabot.yml`) opens one pull request a month for GitHub Actions, as `ci(deps): …`, and one for the minor and patch updates of the Dart packages, as `build(deps): …`. Neither type appears in `CHANGELOG.md` or cuts a release, so the updates ship with the next `feat` or `fix`. When an update fixes something users notice, such as a bug or a vulnerability, rename the squash commit to `fix(deps): …` on merge so that it is released and listed.

A Dart package pull request can fail CI and need finishing on its branch:

- an update of `drift_dev` or `build_runner` changes the generated code: run `task gen` and commit the result;
- an update of `package:sqlite3` needs the vendored SQLite updated too, see `third_party/sqlite/README.md`.

Major versions, Flutter, the Android Gradle Plugin, Kotlin and Gradle are updated by hand, together, since their versions have to match: bump Flutter in `.github/actions/setup/action.yml`, run `flutter pub upgrade --major-versions`, fix what breaks, and run `task check`. If the new Flutter uses another NDK (`flutter.ndkVersion`), change `ndk:` in the F-Droid recipe here and in fdroiddata. Before merging, run the F-Droid check workflow on the branch so that a build that is no longer reproducible shows up before a release.

## Screenshots

The store listing (`fastlane/metadata/android/en-US/images/phoneScreenshots/`, light theme) and the README (also `docs/screenshots/dark/`) use screenshots of demo data, taken on an emulator. Retake both sets when a shown screen changes.

1. `task emulator`, then `task screenshots:prepare`. It reinstalls the app on the emulator (never on a phone), puts a demo backup from `tool/demo_backup.dart` into Downloads and sets the status bar to 9:41 with full battery and no notifications. On emulator images that allow root, the clock is set to 9:41 too, so times in the app match.
2. In the app: Settings → Language → English, Theme → Light, Import → `elimine-demo.json`.
3. Capture with `task screenshots:capture NAME=<name> THEME=light`:
   - `1_home`: Home;
   - `2_log`: Coffee tapped, its sheet collapsed;
   - `3_substance`: the sheet expanded, Month, the previous (full) month;
   - `4_analytics`: Analytics, Year.
4. Switch to Theme → Dark and capture the same four with `THEME=dark`.

If the clock has moved on, restart the app before a shot so "2 h ago" and similar labels match 9:41.
