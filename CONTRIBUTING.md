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

Every push to `main` updates an open release pull request with the next version and its changelog entry. Merging it tags `vX.Y.Z` and creates the GitHub release; the release workflow then runs the full check on the tag, builds the APK, signs it with the release key, verifies the certificate against `.github/release-cert.sha256` and attaches `elimine-X.Y.Z.apk`. If that build fails after the release exists, fix the cause and run the Release workflow manually with the tag to attach the APK.

Do not edit the version in `pubspec.yaml` by hand. It reads `X.Y.Z+N`: release-please sets `X.Y.Z` and raises the build number `N` by one with every release. `N` is the Android version code, and F-Droid reads both values from this line.

F-Droid builds each release tag itself and publishes our APK only if its build is identical apart from the signature. Its recipe is kept in `fdroid/com.elimine.elimine.yml` (see `fdroid/README.md`), and after every release the F-Droid check workflow builds the tag the same way and compares. The Flutter version is pinned in `.github/actions/setup/action.yml` and in the recipe (`srclibs: flutter@X.Y.Z`); upgrading Flutter means changing both, and the recipe in [fdroiddata](https://gitlab.com/fdroid/fdroiddata) through a merge request.

The release key is never committed. Locally, release builds use it only when `android/key.properties` points at it; otherwise they are signed with the debug key.

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
