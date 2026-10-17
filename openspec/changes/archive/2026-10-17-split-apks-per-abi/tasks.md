# Tasks

## 1. Release build per ABI

- [x] 1.1 In `tool/release_build.sh`, set `PUB_CACHE` to `<project>/.pub-cache`, run `flutter pub get --enforce-lockfile`, then build `--release --split-per-abi` once per `--target-platform` (`android-arm`, `android-arm64`, `android-x64`) and copy the three `app-<abi>-release.apk` files back into the checkout's `build/app/outputs/flutter-apk/`. Update the header comment. Verify locally that the same three commands produce APKs with version codes 1002, 2002 and 4002 for the current `0.3.0+2` (`aapt2 dump badging`), each containing only its ABI's libraries
- [x] 1.2 In `.github/workflows/release.yml`, check the certificate of each of the three APKs and attach them as `elimine-$VERSION-<abi>.apk`. Verify with `actionlint`-style YAML parsing and by reading the step against `release_build.sh`'s output names

## 2. F-Droid recipe and check

- [x] 2.1 Rewrite `fdroid/com.elimine.elimine.yml`: `AuthorName`/`AuthorEmail`, no app-level `Binaries`, three build blocks ordered v7a, arm64, x86_64 with `srclibs: flutter@stable`, a `prebuild` that checks out the Flutter version from `.github/actions/setup/action.yml`, runs `tool/fetch_sqlite.sh`, `flutter config --no-analytics` and `flutter pub get --enforce-lockfile` with `PUB_CACHE=$(pwd)/.pub-cache`, `scandelete: .pub-cache`, a `build` with the same `PUB_CACHE` and `--split-per-abi --target-platform`, the ABI's `output` and `binary`, `ndk: r28c`, and `VercodeOperation` `1000 + %c`, `2000 + %c`, `4000 + %c`. Update `fdroid/README.md`. Verify with `fdroid readmeta` and `fdroid lint` in the check run
- [x] 2.2 In `.github/workflows/fdroid-check.yml`, drop the Flutter version comparison, fill in all three blocks (version name, the three version codes, full commit hash, `CurrentVersionCode` of the x86_64 block), run the F-Droid build as a matrix over the three ABIs, and compare each APK with its published counterpart (release mode) or the `release_build.sh` output (branch mode). Add a temporary `push` trigger for the change's branch. Verify a run on the branch passes for all three ABIs, then remove the trigger

## 3. Documentation

- [x] 3.1 README Install: the three APKs, which to pick (`arm64-v8a` for most phones, `armeabi-v7a` for old 32-bit ones, `x86_64` for emulators), and the `apksigner` example with the new name. Verify the links point at `releases/latest`
- [x] 3.2 CONTRIBUTING: the release workflow attaches three APKs; remove the rule that a Flutter upgrade needs an fdroiddata merge request, keeping that recipe changes do. Verify against `fdroid/README.md`

## 4. Integration check

- [x] 4.1 Run `task check` (format, analyzer, tests) and verify it passes
- [x] 4.2 On the emulator, install the APK for its ABI (`arm64-v8a` on Apple silicon, `x86_64` elsewhere) from the branch's release build output over the universal 0.3.0 with `adb install -r` and verify the app starts with its data and Settings shows the version. On the phone nothing is installed in this task

## 5. Release and submission

- [ ] 5.1 Merge to `main` with a `Release-As: 0.3.1` footer, merge the release PR, and verify the release has the three APKs with version codes 1003, 2003 and 4003, and the F-Droid check passes for all three
- [ ] 5.2 Fill `fdroid/com.elimine.elimine.yml` for 0.3.1, fork fdroiddata as `elimineapp`, push a `com.elimine.elimine` branch with `metadata/com.elimine.elimine.yml` (after `fdroid rewritemeta`), and verify the fork's pipeline passes. Show the owner the final merge request text and open it only after their go-ahead
