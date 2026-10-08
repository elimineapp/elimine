# Spec Delta

## MODIFIED Requirements

### Requirement: Version numbers
Versions SHALL follow Semantic Versioning and be derived from the Conventional Commits since the previous release. The first release SHALL be 0.1.0. Before 1.0.0, a release with features or breaking changes SHALL raise the minor number and a release with only fixes SHALL raise the patch number.

#### Scenario: Features since the last release
- **WHEN** the last release is 0.3.2 and a `feat` commit has landed since
- **THEN** the next version is 0.4.0

#### Scenario: Only fixes since the last release
- **WHEN** the last release is 0.3.2 and only `fix` commits have landed since
- **THEN** the next version is 0.3.3

## ADDED Requirements

### Requirement: Version code
The Android version code SHALL be a build number kept in the repository next to the version name and raised by exactly one with every release, so that it grows with every version and can be read from the source of any tag.

#### Scenario: Version code order
- **WHEN** two releases are compared
- **THEN** the later version has the larger Android version code

#### Scenario: Next version code
- **WHEN** the last release had version code 4
- **THEN** the next release has version code 5, whatever its version name

#### Scenario: Version code in the source
- **WHEN** someone checks out the tag of a release
- **THEN** the version name and version code of that release can be read from a file in the checkout, without building the app

### Requirement: Releases on F-Droid
Every version released on GitHub SHALL also become available in the main F-Droid repository as the same APK, signed with the Elimine release key, so that the app installed from either source updates from the other without reinstalling. F-Droid SHALL be able to build each release tag from source into an APK identical to the published one apart from the signature.

#### Scenario: Installing from F-Droid
- **WHEN** a user searches for "Elimine" in the F-Droid client
- **THEN** it offers the app and installs its latest version

#### Scenario: Same signature as on GitHub
- **WHEN** a user checks the certificate of the APK installed from F-Droid
- **THEN** its SHA-256 fingerprint equals the one in the README

#### Scenario: Switching sources
- **WHEN** a user who installed a release from GitHub installs a newer one from F-Droid
- **THEN** Android accepts it as an update
- **AND** the user's data stays in place

#### Scenario: Reproducible build
- **WHEN** F-Droid builds a release tag from source with the documented toolchain
- **THEN** the result differs from the APK attached to the GitHub release only in its signature

#### Scenario: Mismatch found before F-Droid
- **WHEN** a release is published and a build of its tag made the way F-Droid builds differs from the published APK beyond the signature
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
