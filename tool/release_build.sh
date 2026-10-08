#!/usr/bin/env bash
# Builds the release APK on a Linux CI runner the way F-Droid's build server
# does, so that F-Droid's build of the same tag is byte-identical and F-Droid
# can publish our signed APK. Paths end up in the Dart snapshot and in the
# build IDs of native libraries, and the hooks' native code depends on the
# NDK, so this mirrors F-Droid's layout:
#
#   project   /home/vagrant/build/com.elimine.elimine
#   pub cache /home/vagrant/.pub-cache (F-Droid builds with HOME=/home/vagrant)
#   SDK       /opt/android-sdk, NDK r28c (`ndk: r28c` in the F-Droid recipe;
#             Flutter's default NDK for the pinned version)
#
# Leaves the APK at build/app/outputs/flutter-apk/app-release.apk in the
# checkout. Signing uses android/key.properties when it exists, as locally.
set -euo pipefail

ndk_version=28.2.13676358
project=/home/vagrant/build/com.elimine.elimine

sudo mkdir -p "$project" /opt
sudo chown -R "$USER" /home/vagrant
sudo ln -sfn "$ANDROID_HOME" /opt/android-sdk

export ANDROID_HOME=/opt/android-sdk ANDROID_SDK_ROOT=/opt/android-sdk
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --install "ndk;$ndk_version" >/dev/null
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$ndk_version"
export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME" ANDROID_NDK="$ANDROID_NDK_HOME"
unset ANDROID_NDK_LATEST_HOME
export PUB_CACHE=/home/vagrant/.pub-cache

rsync -a --delete --exclude .git --exclude .dart_tool --exclude build ./ "$project/"
(cd "$project" && flutter pub get && flutter build apk --release)

mkdir -p build/app/outputs/flutter-apk
cp "$project/build/app/outputs/flutter-apk/app-release.apk" build/app/outputs/flutter-apk/
