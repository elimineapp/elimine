# releases Specification

## Purpose

How a version of Elimine reaches users: signed APKs published on GitHub Releases, version numbers and a changelog, and the installed version shown in the app so users can match it with a release.

## Requirements

### Requirement: Releases on GitHub
Every version SHALL be published as a GitHub release of github.com/elimineapp/elimine, tagged `vX.Y.Z`, with one APK per supported processor architecture, named `elimine-X.Y.Z-<abi>.apk` for `armeabi-v7a`, `arm64-v8a` and `x86_64`, and with that version's changelog entry as the release notes.

#### Scenario: Downloading a release
- **WHEN** a user opens the latest release on GitHub
- **THEN** it offers `elimine-X.Y.Z-armeabi-v7a.apk`, `elimine-X.Y.Z-arm64-v8a.apk` and `elimine-X.Y.Z-x86_64.apk` for that version
- **AND** its notes list the changes in that version

#### Scenario: Installing on any device
- **WHEN** a user installs the APK for their device's processor architecture on a supported device
- **THEN** the app installs and starts

#### Scenario: Choosing the APK
- **WHEN** a user does not know their phone's architecture
- **THEN** the README tells them that most phones need `arm64-v8a` and older 32-bit phones `armeabi-v7a`

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
Versions SHALL follow Semantic Versioning and be derived from the Conventional Commits since the previous release. The first release SHALL be 0.1.0. Before 1.0.0, a release with features or breaking changes SHALL raise the minor number and a release with only fixes SHALL raise the patch number.

#### Scenario: Features since the last release
- **WHEN** the last release is 0.3.2 and a `feat` commit has landed since
- **THEN** the next version is 0.4.0

#### Scenario: Only fixes since the last release
- **WHEN** the last release is 0.3.2 and only `fix` commits have landed since
- **THEN** the next version is 0.3.3

### Requirement: Version code
The Android version code SHALL be 1000 times the architecture's number (1 for `armeabi-v7a`, 2 for `arm64-v8a`, 4 for `x86_64`) plus a build number kept in the repository next to the version name and raised by exactly one with every release, so that for each architecture it grows with every version and can be worked out from the source of any tag.

#### Scenario: Version code order
- **WHEN** two releases are compared on the same architecture
- **THEN** the later version has the larger Android version code

#### Scenario: Next version code
- **WHEN** the last release had build number 4
- **THEN** the next release has build number 5 and its `arm64-v8a` APK has version code 2005, whatever its version name

#### Scenario: Version code in the source
- **WHEN** someone checks out the tag of a release
- **THEN** the version name and build number of that release can be read from a file in the checkout, without building the app

#### Scenario: Updating from the universal APK
- **WHEN** a phone runs the universal 0.3.0 APK (version code 2) and the user installs the `arm64-v8a` APK of a later release
- **THEN** Android accepts it as an update
- **AND** the user's data stays in place

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

### Requirement: Releases on F-Droid
Every version released on GitHub SHALL also become available in the main F-Droid repository as the same per-architecture APKs, signed with the Elimine release key, so that the app installed from either source updates from the other without reinstalling. F-Droid SHALL be able to build each release tag from source into APKs identical to the published ones apart from the signature.

#### Scenario: Installing from F-Droid
- **WHEN** a user searches for "Elimine" in the F-Droid client
- **THEN** it offers the app and installs the latest version's APK for the device's architecture

#### Scenario: Same signature as on GitHub
- **WHEN** a user checks the certificate of the APK installed from F-Droid
- **THEN** its SHA-256 fingerprint equals the one in the README

#### Scenario: Switching sources
- **WHEN** a user who installed a release from GitHub installs a newer one from F-Droid, or the other way round
- **THEN** Android accepts it as an update
- **AND** the user's data stays in place

#### Scenario: Reproducible build
- **WHEN** F-Droid builds a release tag from source with the documented toolchain
- **THEN** each resulting APK differs from the APK for the same architecture attached to the GitHub release only in its signature

#### Scenario: Mismatch found before F-Droid
- **WHEN** a release is published and a build of its tag made the way F-Droid builds differs from a published APK beyond the signature
- **THEN** the release workflow fails with the differing files, without waiting for F-Droid to skip the version

### Requirement: Built from source
Every part of a release APK, including native libraries, SHALL be built from source code that is in the repository or pinned by version and checksum. A release build SHALL NOT download prebuilt binaries, and the APK SHALL NOT contain blobs that only a third party can read.

#### Scenario: SQLite
- **WHEN** a release APK is built
- **THEN** its SQLite library is compiled from source during the build rather than downloaded

#### Scenario: Tampered SQLite source
- **WHEN** the downloaded SQLite source does not match its pinned checksum
- **THEN** the build fails before compiling anything

#### Scenario: Dependency metadata
- **WHEN** the signing blocks of a release APK are listed
- **THEN** it has no encrypted dependency metadata block

### Requirement: Store listing
The repository SHALL contain the app's store listing in English and Russian: title, short description, full description, icon and phone screenshots. The texts SHALL describe the app as it is at that commit, including that it works without network access, accounts or tracking.

#### Scenario: Listing in the user's language
- **WHEN** a user with a Russian system language opens Elimine in the F-Droid client
- **THEN** its description is in Russian

#### Scenario: Screenshots
- **WHEN** a user opens Elimine in the F-Droid client
- **THEN** it shows phone screenshots of Home, logging an intake, a substance's chart and Analytics, in the light theme, with demo data and no personal data
