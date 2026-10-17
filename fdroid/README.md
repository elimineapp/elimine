# F-Droid

`com.elimine.elimine.yml` is the app's recipe as it is in [fdroiddata](https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/com.elimine.elimine.yml), with one build block per ABI (`armeabi-v7a`, `arm64-v8a`, `x86_64`) whose version and commit are placeholders. F-Droid builds every release tag from it and publishes our signed APK for each ABI only if its build is identical apart from the signature; otherwise it skips that version.

The recipe follows fdroiddata's Flutter template: it checks out the Flutter version named in `.github/actions/setup/action.yml`, keeps the pub cache inside the project so F-Droid's scanner covers the Dart packages, and builds each ABI with `--split-per-abi`. Flutter gives each APK the version code `1000 × ABI + build number` (1, 2 and 4), which `VercodeOperation` repeats.

`.github/workflows/fdroid-check.yml` runs those builds the way F-Droid's build server does after every release (and on demand), and compares each result with the published `elimine-X.Y.Z-<abi>.apk`.

When the recipe changes here (a new build step, a different NDK), make the same change in fdroiddata's copy through a merge request. A Flutter upgrade needs no change there. F-Droid's auto-update copies the last three build blocks for each new version, so its copy only needs to change when ours does.

The release build mirrors F-Droid's paths, pub cache and NDK in `tool/release_build.sh`; see the comment there for why.
