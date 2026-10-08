# F-Droid

`com.elimine.elimine.yml` is the app's recipe as it is in [fdroiddata](https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/com.elimine.elimine.yml), with one build block whose version and commit are placeholders. F-Droid builds every release tag from it and publishes our signed APK only if its build is identical apart from the signature; otherwise it skips that version.

`.github/workflows/fdroid-check.yml` runs that build the way F-Droid's build server does after every release (and on demand), and compares the result with the published `elimine-X.Y.Z.apk`. It fails when the Flutter version here differs from the one in `.github/actions/setup/action.yml`.

When the recipe changes here (a Flutter upgrade, a new build step, a different NDK), make the same change in fdroiddata's copy through a merge request. F-Droid's auto-update copies the last build block for each new version, so its copy only needs to change when ours does.

The release build mirrors F-Droid's paths and NDK in `tool/release_build.sh`; see the comment there for why.
