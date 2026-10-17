# Spec Delta

## MODIFIED Requirements

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
