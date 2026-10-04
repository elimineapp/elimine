## Why

Elimine has only ever run as debug builds installed from a laptop. To let other people use it, the code needs a public home (github.com/elimineapp/elimine) and every release needs a build that installs over the previous one: signed with one long-lived key, versioned consistently, with a changelog that says what changed. Doing this by hand invites mistakes that cannot be undone, such as publishing a debug-signed APK or losing the key, so the process should be automated from the first release.

## What Changes

- Publish the existing history to github.com/elimineapp/elimine under the GPL-3.0 license, with a README that describes the app, how to install it and how to verify the signing certificate.
- Release builds are signed with a dedicated Elimine release key. The key lives outside the repository: the original with the maintainer (with an offline backup), a copy in GitHub Actions secrets. Local release builds without the key keep working with the debug key, but CI never publishes one.
- Continuous integration on every push and pull request: generated code is up to date and `task check` passes.
- Versioning and changelog by release-please from Conventional Commits: it keeps a release pull request with the next version and the `CHANGELOG.md` entry; merging it tags `vX.Y.Z` and creates the GitHub release, after which CI builds the signed APK and attaches it.
- The Android version code is derived from the version name, so it always grows with the version and never needs a manual bump.
- The Settings screen shows the installed version, so a user can match it with a release.
- Out of scope, kept on the roadmap: F-Droid, Google Play, RuStore, privacy policy and store listings.

## Capabilities

### New Capabilities
- `releases`: how a version of the app reaches users: signed APKs on GitHub Releases, version numbering, changelog, and the installed version shown in the app.

### Modified Capabilities

## Impact

- New files: `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `release-please-config.json`, `.release-please-manifest.json`, `CHANGELOG.md` (created by release-please), `LICENSE`, the signing certificate fingerprint file; README rewritten.
- `android/app/build.gradle.kts`: release signing from `android/key.properties`, version code derived from the version name. `.gitignore`: key files.
- `pubspec.yaml`: version reset to `0.0.0` so that the first release is `0.1.0`; new dependency `package_info_plus` for reading the installed version.
- Settings screen: a version row; new localized strings.
- `CONTRIBUTING.md`: the release process; `docs/roadmap.md`: the remaining publishing channels.
- Manual, outside the repository: creating and backing up the key, GitHub secrets and repository settings, pushing to the remote.
