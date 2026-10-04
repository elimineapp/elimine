## Context

- The repository has no remote yet; github.com/elimineapp/elimine exists and is empty. The whole history is authored by `Elimine <elimine.app@gmail.com>` and contains no personal names or local paths.
- `android/app/build.gradle.kts` signs release builds with the debug key (Flutter template default). `pubspec.yaml` has `version: 1.0.0+1`, and the version code comes from the build number after `+`.
- Generated code (`database.g.dart`, `lib/l10n/app_localizations*.dart`) is committed. `task check` runs format, analyze and tests; `task gen` regenerates.
- Commits already follow Conventional Commits (CONTRIBUTING.md), which is what release-please needs.
- The maintainer's phone runs a debug-signed build with real data.

## Goals / Non-Goals

**Goals:**
- A release is one merge: no manual version bumps, tags, builds or uploads.
- The release key never appears in the repository or in logs, and a wrongly signed APK can never be published.
- Builds are reproducible from a tag: the same Flutter version and a version code derived from the tag.

**Non-Goals:**
- F-Droid metadata, Play/RuStore bundles (AAB), per-ABI APKs, in-app update checks.
- Dependency update bots.

## Decisions

### release-please in the same workflow as the APK build
`release.yml` runs on every push to `main`. Its first job runs `googleapis/release-please-action`, which keeps the release PR up to date or, when that PR has just been merged, creates the tag and the GitHub release. Later jobs run only when a release was created: the shared check, then the APK build and upload.

Why one workflow: tags and releases created with `GITHUB_TOKEN` do not trigger other workflows, so a separate "on tag" workflow would never start. A personal access token would avoid that but adds a long-lived secret tied to a person, which goes against the Elimine identity.

`release.yml` also accepts `workflow_dispatch` with a `tag` input to rebuild and attach the APK for an existing release, in case the build failed after the release had been created.

Configuration (`release-please-config.json` and `.release-please-manifest.json`):
- `release-type: dart`, which updates `version:` in `pubspec.yaml`, the manifest and `CHANGELOG.md`.
- `include-component-in-tag: false`, so tags are `vX.Y.Z`.
- `bump-minor-pre-major: true`, so a breaking change before 1.0.0 raises the minor number instead of jumping to 1.0.0.
- `changelog-sections`: Features (`feat`), Bug Fixes (`fix`), Performance (`perf`), Reverts (`revert`) are visible; `docs`, `test`, `ci`, `build`, `chore`, `refactor`, `style` are hidden.
- `initial-version: 0.1.0`: with no previous release, release-please would otherwise start at 1.0.0. The manifest starts at `0.0.0` and `pubspec.yaml` is reset to `version: 0.0.0`; the Dart updater rewrites that line and leaves no build number.

Alternatives: hand-written CHANGELOG with manual tags. The maintainer chose release-please.

### Version code derived from the version name
`build.gradle.kts` computes `versionCode = major * 1_000_000 + minor * 1_000 + patch` from `flutter.versionName`, at least 1. `pubspec.yaml` carries only `X.Y.Z`, without `+build`.

Why: the code always grows with the version, both locally and in CI, and there is nothing to bump. That matters later for F-Droid, which builds from the tag itself. This also avoids relying on how release-please's Dart updater treats a `+build` suffix. The limits (minor and patch below 1000, major below 2100) are far away.

Alternatives: the CI run number (not reproducible from the tag), or a `+N` that release-please would have to increment (behavior not guaranteed).

### Signing
- `build.gradle.kts` loads `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`) when the file exists and signs release builds with it; otherwise it keeps the debug key, so `flutter run --release` and `task build:apk` still work locally. `.gitignore` gets `android/key.properties`, `*.jks` and `*.keystore`.
- The key is created once by the maintainer with `keytool`: PKCS12, RSA 4096, alias `elimine`, validity 10,000 days, DN `CN=Elimine`. The certificate is public inside every APK, so the DN must contain nothing personal.
- Backups: the keystore and its password go to a password manager and to one offline copy. Losing the key means no more updates for installed apps.
- GitHub: the secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` live in a `release` environment that only `main` and `v*` tags may use. Only the APK job references that environment, so pull requests and other jobs never see the key.
- The APK job writes the keystore to `$RUNNER_TEMP` and fails before building if any secret is empty. After the build, it compares the certificate SHA-256 from `apksigner verify --print-certs` with the committed `.github/release-cert.sha256` and fails on mismatch. That is what makes a debug-signed upload impossible, as the spec requires. The same fingerprint is in the README.

### Shared CI
- A composite action `.github/actions/setup` installs Java 17 (Temurin), Flutter (pinned to the exact version used here, 3.47.5, in that one file) and Task, then runs `flutter pub get`.
- `ci.yml` runs on `push`, `pull_request` and `workflow_call`: setup, then `task gen` and `git diff --exit-code` (generated code is current), then `task check`. `release.yml` calls it as a reusable workflow before building, so a release commit is checked even though CI does not run on PRs opened by release-please (they are created with `GITHUB_TOKEN`).
- Third-party actions are pinned to full commit SHAs with the version in a comment. The release job handles the key, so a moved tag must not be able to change what runs there.

### APK
`flutter build apk --release` builds one universal APK, renamed to `elimine-X.Y.Z.apk` and attached with `gh release upload`. Universal costs size (about 3x the native code) but gives one obvious download for every device.

### Installed version in Settings
`package_info_plus` reads the version name from the installed package, so it is always the one the build really carries. A `FutureProvider` exposes it and tests override it. Settings gets a non-interactive last `ListTile` with an info icon, the title "Version" and the version name as subtitle.

Alternative: a constant generated into Dart by release-please (`extra-files`). It needs no plugin, but it duplicates the version and can drift in local builds.

### License and README
GPL-3.0-or-later: the full license text goes in `LICENSE` and the SPDX id goes in the README. Every dependency is MIT, BSD or Apache-2.0, all compatible with it. The README covers what the app does and does not do (no network, no accounts), installing from Releases, verifying the certificate fingerprint, building from source with `task`, how releases work, and the license.

## Risks / Trade-offs

- [The release is public for a few minutes before its APK is attached, or stays without an APK if the build fails] → the release body is the changelog anyway, and the `workflow_dispatch` rebuild attaches the APK once fixed.
- [Losing the key ends updates for every install] → password manager plus an offline copy, done before the first release (a task, not a suggestion).
- [A leaked key lets someone sign "updates"] → the key exists only in the environment-scoped secrets and the maintainer's backups, actions are pinned by SHA, and PRs from forks never get secrets.
- [The release-please PR gets no CI run] → the release workflow runs the full check before building, so a broken release fails before an APK exists.
- [Changing signing keys forces a reinstall] → see the migration plan.

## Migration Plan

1. Merge this change locally and create the key, its backups, the `release` environment and its secrets, and the fingerprint file.
2. In the repository settings, allow GitHub Actions to create pull requests.
3. Add the remote and push `main`. CI runs, and release-please opens the 0.1.0 release PR.
4. Review the PR (version, CHANGELOG) and merge it. The workflow tags `v0.1.0` and attaches the signed APK.
5. Move the phone over. The release key differs from the debug key, so Android will not update the debug build in place. Install the current debug build over the old one (same debug key, data stays) to get export, export a backup, uninstall, install `elimine-0.1.0.apk`, then import. Back up the database file first, as always.

Rollback: delete the GitHub release and tag. Nothing is lost locally, and the debug build can be reinstalled.
