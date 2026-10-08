# Tasks

## 1. Build everything from source

- [x] 1.1 Find the SQLite version behind the prebuilt binaries of `package:sqlite3` 3.5.2 (its hook sources or release notes), download that version's amalgamation from sqlite.org and check it against the published sha3-256. Add `third_party/sqlite/VERSION` (version, URL, archive SHA3-256, `sqlite3.c` SHA-256), `README.md` (origin, public domain, how to update, recheck the hook docs when upgrading `package:sqlite3`) and `tool/fetch_sqlite.sh`, run by `task deps`, which downloads and checks the archive and extracts `sqlite3.c` (ignored by git). Verify that `task deps` fetches the file, a second run does nothing, a wrong hash fails, and `git status` does not list `sqlite3.c`
- [x] 1.2 Add the `hooks.user_defines.sqlite3` section (`source: source`, `path: third_party/sqlite/sqlite3.c`) to `pubspec.yaml`. After `flutter clean`, build a release APK and verify that `.dart_tool/hooks_runner/shared/sqlite3/build/` has no `download-*` directory, that the APK contains `libsqlite3.so` for every ABI, and that `task check` passes (the database tests now use SQLite compiled for the host)
- [x] 1.3 Add `dependenciesInfo { includeInApk = false; includeInBundle = false }` to `android/app/build.gradle.kts`. Verify with `fdroid scanner` in the fdroidserver container (or by listing the APK signing block ids) that the release APK has no dependency metadata block
- [x] 1.4 Make the CI release build work with the hook: run `ci.yml` and a manual `Release` dry run on a branch, or reproduce the workflow's build steps in a clean Ubuntu container, and verify the APK builds without network access to github.com/simolus3

## 2. Reproducibility check (gate)

- [x] 2.1 Build release APKs of the same commit in two different checkout directories and compare their contents, then rebuild from clean in one directory. Verify that builds at the same path are byte-identical and record what differs between paths in design.md
- [x] 2.2 Write the draft `fdroiddata` recipe from design.md, run `fdroid lint` and `fdroid build` for it in `registry.gitlab.com/fdroid/fdroidserver:buildserver`, and compare that APK with one built by our release workflow steps and signed with the release key. Verify `apksigcopier compare` reports them equal apart from the signature
- [x] 2.3 Make the "Build" step of `.github/workflows/release.yml` build in `/home/vagrant/build/com.elimine.elimine` (a copy of the checked-out tag) and take the APK from there; document why in a comment. Verify by building our release APK the same way in a Linux container and comparing it with the F-Droid build from 2.2
- [x] 2.4 (Not needed: 2.1–2.3 pass.) If 2.1, 2.2 or 2.3 cannot be made to pass, stop and report the remaining differences to the owner for the decision described in design.md, then update the `Releases on F-Droid` requirement and these tasks to match it

## 3. Version code from the build number

- [x] 3.1 Set `version: 0.2.0+1` in `pubspec.yaml` and update its comment; in `android/app/build.gradle.kts`, remove `versionCodeOf` and its comment and use `flutter.versionCode`. Verify a release build has version code 1 and version name 0.2.0 (`aapt2 dump badging` or `apkanalyzer manifest version-code`)
- [x] 3.2 Change the "Version matches the tag" step in `.github/workflows/release.yml` to accept `version: X.Y.Z+N`. Verify the check passes on `version: 0.3.0+2` with tag `v0.3.0` and fails on `version: 0.3.1+2` and on a line without a build number (run the step's script locally)
- [x] 3.3 Run release-please's Dart updater logic on the new line (or check the release PR after merge) and verify it proposes `0.3.0+2`; update the version paragraph in `CONTRIBUTING.md` (build number raised by release-please, never edited by hand, F-Droid reads it) and add that a Flutter upgrade also needs the `srclibs` version in the fdroiddata recipe

## 4. Store listing

- [x] 4.1 Add `fastlane/metadata/android/en-US/` with `title.txt`, `short_description.txt` (80 characters or fewer) and `full_description.txt` following the README's "What it does" and "What it does not do", and `images/icon.png` copied from `design/icon/android/play-store-512.png`. Verify the short description's length and that the full description mentions no network access, no accounts and no tracking
- [x] 4.2 Add `fastlane/metadata/android/ru-RU/` with the same three texts in Russian, using the app's Russian terms from `lib/l10n/app_ru.arb`. Verify the files are UTF-8 and the short description is 80 characters or fewer
- [x] 4.3 Verify the metadata layout with `fdroid lint` (or `fdroid readmeta` with the draft recipe) in the fdroidserver container

## 5. Screenshots

- [x] 5.1 Add `tool/demo_backup.dart`, which writes the demo backup from design.md (five substances, about nine months, dates relative to now or to a given local time, UUIDv5 ids, fixed random seed) to a path given as an argument. Add a test that runs its generator and imports the result with the backup service into an empty database, and verify the counts of substances and intakes and that importing it a second time adds nothing
- [x] 5.2 Add Task targets `screenshots:prepare` (install a release build on the `elimine_pixel8` emulator, push the demo backup to Downloads, turn on system UI demo mode with clock 9:41 and full battery) and `screenshots:capture NAME=... THEME=light|dark` (save `adb exec-out screencap -p` into the light or dark directory). Both refuse to run when the target device is not an emulator. Verify `task --list` shows them and a test capture lands in the right place
- [x] 5.3 On the emulator, import the demo backup and capture `1_home`, `2_log`, `3_substance` and `4_analytics` in the light theme into `fastlane/metadata/android/en-US/images/phoneScreenshots/` and in the dark theme into `docs/screenshots/dark/`. Verify each image shows only demo data, the 9:41 status bar, no debug banner and the intended screen state
- [x] 5.4 Document the screenshot steps in `CONTRIBUTING.md` (or a short `docs/screenshots.md` linked from it) and verify the documented commands match the Task targets

## 6. Documentation

- [x] 6.1 Update `README.md`: the screenshot row with `<picture>` light/dark sources (200 px wide), the feature list (editing and deleting an intake, reordering substances on Home, language and theme), and the note that 0.1.0 and 0.2.0 cannot be updated in place. Verify every image and link resolves by previewing the README on a GitHub branch in light and dark theme
- [x] 6.2 In `docs/backup-format.md`, add app settings (language, theme, first day of the week) to "What is not in the file". In `docs/roadmap.md`, rewrite the F-Droid item to reflect this change. Verify the wording matches `SettingsService`
- [x] 6.3 Run `openspec validate publish-on-fdroid --strict` and verify it passes

## 7. Integration check

- [x] 7.1 Run `task check` (format, analyzer, tests) and verify it passes
- [x] 7.2 On the emulator, install the release build over a clean state, import the demo backup, log and edit an intake, open a substance chart and Analytics, and export a backup. Verify everything works as before with the SQLite built from source and Settings shows "Version 0.2.0"

- [x] 7.3 Turn the comparison into a permanent check: `fdroid/com.elimine.elimine.yml` with `fdroid/README.md`, `.github/workflows/fdroid-check.yml` (`workflow_call` from `release.yml` after the APK job, `workflow_dispatch` for a tag or branch; a release tag is compared with its published APK, a branch with a `tool/release_build.sh` build), failing when the recipe's Flutter version differs from CI's. Verify a run on this branch passes, then remove its temporary `push` trigger before merging

## 8. Release and submission

- [x] 8.1 Move the steps that can only happen after merging (phone migration, the 0.3.0 release, the fdroiddata merge request, the F-Droid badge in the README) to the F-Droid item in `docs/roadmap.md`. Verify the roadmap lists all four
