## 1. Version and signing in Gradle

- [x] 1.1 Set `version: 0.0.0` in `pubspec.yaml` and derive `versionCode` from `flutter.versionName` in `android/app/build.gradle.kts` (`major * 1_000_000 + minor * 1_000 + patch`, at least 1); verify with `aapt2 dump badging` that a release APK reports version code 1 for 0.0.0 and 1002003 for `--build-name 1.2.3`
- [x] 1.2 Load release signing from `android/key.properties` when present, fall back to the debug key otherwise, and add `android/key.properties`, `*.jks`, `*.keystore` to `.gitignore`; verify `task build:apk` still builds without the file and `git status` does not show a test `key.properties`
- [x] 1.3 Verify the release manifest requests no `INTERNET` permission (`aapt2 dump permissions`), since the README will say so

## 2. Installed version in Settings

- [x] 2.1 Add `package_info_plus`, an `appVersionProvider` (`FutureProvider<String>`) and a last, non-interactive "Version" row in Settings with the version name as subtitle; add the `version` string to `app_en.arb` and `app_ru.arb`
- [x] 2.2 Widget test: with the provider overridden to `0.1.0`, Settings shows "Version" and "0.1.0" as the last row; verify `task test` passes
- [x] 2.3 Manual check on the emulator: Settings shows "Version 0.0.0" under the backup rows

## 3. CI and release workflows

- [x] 3.1 Add the composite action `.github/actions/setup` (Java 17 Temurin, Flutter 3.47.5, Task, `flutter pub get`), with third-party actions pinned to commit SHAs
- [x] 3.2 Add `.github/workflows/ci.yml` (`push`, `pull_request`, `workflow_call`): setup, `task gen` + `git diff --exit-code`, `task check`; verify locally that `task gen` leaves the tree clean
- [x] 3.3 Add `release-please-config.json` (dart, no component in tag, `initial-version` 0.1.0, `bump-minor-pre-major`, changelog sections from design) and `.release-please-manifest.json` at `0.0.0`
- [x] 3.4 Add `.github/workflows/release.yml`: release-please job; when a release is created (or on `workflow_dispatch` with a `tag`), call `ci.yml`, then in the `release` environment fail on empty secrets, decode the keystore to `$RUNNER_TEMP`, build the APK, compare the certificate SHA-256 with `.github/release-cert.sha256`, rename to `elimine-X.Y.Z.apk` and `gh release upload`; minimal `permissions` per job
- [x] 3.5 Run `actionlint` on both workflows and the composite action (install via Homebrew if missing); verify it reports no errors

## 4. Release key (maintainer, manual)

- [x] 4.1 Maintainer creates the keystore outside the repository: `keytool -genkeypair -v -storetype PKCS12 -keystore elimine-release.jks -alias elimine -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Elimine"`; verify `keytool -list -v` shows `CN=Elimine` and nothing personal
- [x] 4.2 Maintainer stores the keystore and password in a password manager and one offline copy
- [x] 4.3 Write the certificate SHA-256 to `.github/release-cert.sha256`; with a local `android/key.properties` pointing at the keystore, build a release APK and verify `apksigner verify --print-certs` shows the same fingerprint; then delete the local `key.properties` or keep it ignored
- [x] 4.4 Maintainer creates the `release` environment in github.com/elimineapp/elimine (deployment branches: `main` and `v*` tags), adds the four `ANDROID_*` secrets to it, and enables "Allow GitHub Actions to create and approve pull requests"

## 5. Documentation and license

- [x] 5.1 Add `LICENSE` with the GPL-3.0 text and rewrite `README.md`: what the app does and does not do, installing from Releases, the certificate fingerprint and how to verify it, building from source with `task`, license (GPL-3.0-or-later); verify the fingerprint in the README matches `.github/release-cert.sha256`
- [x] 5.2 Describe the release process in `CONTRIBUTING.md` (Conventional Commits drive versions, merging the release PR publishes) and replace the roadmap item with the remaining channels (F-Droid, Google Play, RuStore, privacy policy, store assets)
- [x] 5.3 Run `task check` and verify it passes
