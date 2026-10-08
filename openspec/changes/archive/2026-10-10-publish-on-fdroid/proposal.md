# Proposal

## Why

Elimine is only available as an APK on GitHub Releases, which few people look for and which gives no update notifications. F-Droid is the natural home for a private, offline, open-source app: its users look for exactly this, and its client installs and updates apps without accounts or tracking. The app already meets F-Droid's inclusion policy (free license, no trackers, no network), but its build does not yet meet F-Droid's build rules, and the repository has no store listing.

## What Changes

- The app is published in the main F-Droid repository through a reproducible build: F-Droid builds each tag from source, checks that the result matches our signed APK on GitHub Releases and distributes our APK, so users can move between GitHub and F-Droid without reinstalling. Whether this is achievable is checked first; if the builds cannot be made to match, the choice between an F-Droid-signed build and postponing is made then.
- SQLite is compiled from source as part of the build instead of being downloaded as a prebuilt library from GitHub during the build, which F-Droid does not allow.
- The APK no longer carries the Google-encrypted "dependency metadata" signing block, which F-Droid rejects.
- **BREAKING**: The Android version code becomes a build number in `pubspec.yaml` that release-please raises by one with every release, starting again from 1, instead of a value computed from the version name (0.2.0 had 2000). F-Droid can only read a version code that is written in the repository. Installs of 0.1.0 or 0.2.0 cannot be updated to the next release and have to be reinstalled; the only such user exports a backup and imports it after reinstalling.
- The repository gets a store listing in the fastlane layout F-Droid reads: title, short and full description, icon and phone screenshots, in English and Russian.
- Screenshots are taken on an emulator from a generated demo backup, in a light and a dark set. The light set is the store's; the README shows both, picking the set that matches the reader's GitHub theme.
- The README gets the screenshots, an F-Droid install option, and the features added since it was written (editing and deleting an intake, reordering substances, language and theme). The backup format document notes that settings are not part of a backup.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `releases`: the version code comes from a build number that grows by one per release; new requirements for distribution through F-Droid with the Elimine signature, for building every part of the APK from source, and for a store listing kept in the repository.

## Impact

- `pubspec.yaml`: version gets a `+N` build number; a `hooks.user_defines` section makes `package:sqlite3` compile SQLite from the official amalgamation.
- New `third_party/sqlite/VERSION` pinning the SQLite amalgamation by URL and hashes, and `tool/fetch_sqlite.sh`, run by `task deps`, which downloads and checks it. The source itself is not committed.
- `android/app/build.gradle.kts`: the version code formula is removed; `dependenciesInfo` is turned off.
- `.github/workflows/release.yml`: the "Version matches the tag" check accepts a build number.
- New `fastlane/metadata/android/{en-US,ru-RU}/` with texts, icon and screenshots.
- A script that generates the demo backup used for screenshots.
- `fdroid/com.elimine.elimine.yml` (our copy of the F-Droid recipe) and `.github/workflows/fdroid-check.yml`, which builds each release the way F-Droid does and compares it with the published APK; `release.yml` runs it after every release.
- `README.md`, `CONTRIBUTING.md` (version code, F-Droid), `docs/backup-format.md`, `docs/roadmap.md` (F-Droid moves from plan to done).
- Outside the repository: a merge request to `fdroiddata` with the app's metadata, and a one-time reinstall of the app on the owner's phone with a backup and restore.
- No app behavior, data, database or backup format changes.
