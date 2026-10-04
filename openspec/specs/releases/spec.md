# releases Specification

## Purpose

How a version of Elimine reaches users: signed APKs published on GitHub Releases, version numbers and a changelog, and the installed version shown in the app so users can match it with a release.

## Requirements

### Requirement: Releases on GitHub
Every version SHALL be published as a GitHub release of github.com/elimineapp/elimine, tagged `vX.Y.Z`, with one APK named `elimine-X.Y.Z.apk` that installs on every device the app supports, and with that version's changelog entry as the release notes.

#### Scenario: Downloading a release
- **WHEN** a user opens the latest release on GitHub
- **THEN** it offers `elimine-X.Y.Z.apk` for that version
- **AND** its notes list the changes in that version

#### Scenario: Installing on any device
- **WHEN** a user installs the APK on a supported device, whatever its processor architecture
- **THEN** the app installs and starts

### Requirement: Stable signing identity
Every published APK SHALL be signed with the Elimine release key, and the SHA-256 fingerprint of its certificate SHALL be published in the README. An APK signed with any other key, including the debug key, SHALL NOT be published.

#### Scenario: Updating keeps the data
- **WHEN** a user installs a newer release over an older one
- **THEN** Android accepts it as an update
- **AND** the user's data stays in place

#### Scenario: Verifying the download
- **WHEN** a user checks the certificate of a downloaded APK
- **THEN** its SHA-256 fingerprint equals the one in the README

#### Scenario: Release key unavailable
- **WHEN** a release build runs without the release key, or the APK's certificate does not match the published fingerprint
- **THEN** the build fails and no APK is attached to the release

### Requirement: Only verified code is released
A release APK SHALL be built only from a commit for which formatting, the analyzer and all tests pass and the generated code matches its sources.

#### Scenario: Failing check
- **WHEN** a test fails on the commit being released
- **THEN** no APK is built or attached

### Requirement: Version numbers
Versions SHALL follow Semantic Versioning and be derived from the Conventional Commits since the previous release. The first release SHALL be 0.1.0. Before 1.0.0, a release with features or breaking changes SHALL raise the minor number and a release with only fixes SHALL raise the patch number. The Android version code SHALL grow with every version.

#### Scenario: Features since the last release
- **WHEN** the last release is 0.3.2 and a `feat` commit has landed since
- **THEN** the next version is 0.4.0

#### Scenario: Only fixes since the last release
- **WHEN** the last release is 0.3.2 and only `fix` commits have landed since
- **THEN** the next version is 0.3.3

#### Scenario: Version code order
- **WHEN** two releases are compared
- **THEN** the later version has the larger Android version code

### Requirement: Changelog
`CHANGELOG.md` SHALL list every released version, newest first, with its date and its user-facing changes (features, fixes and performance improvements), each linked to its commit. Commits that only touch docs, tests, CI or tooling SHALL NOT appear in it.

#### Scenario: New release
- **WHEN** a version is released
- **THEN** `CHANGELOG.md` gains an entry for it at the top, matching the release notes on GitHub

### Requirement: Installed version
The Settings screen SHALL show the installed version name (for example, "Version 0.1.0") at the bottom of its list.

#### Scenario: Checking the version
- **WHEN** the user opens Settings
- **THEN** the last row shows "Version" with the version name of the installed build
