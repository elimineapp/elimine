#!/usr/bin/env bash
# Builds the release APKs, one per ABI, on a Linux CI runner the way F-Droid's
# build server runs fdroid/com.elimine.elimine.yml, so that F-Droid's builds of
# the same tag are byte-identical and F-Droid can publish our signed APKs. Paths end up in the Dart snapshot and in the
# build IDs of native libraries, and the hooks' native code depends on the
# NDK, so this mirrors F-Droid's layout:
#
#   project   /home/vagrant/build/com.elimine.elimine
#   pub cache <project>/.pub-cache (the recipe's PUB_CACHE, so F-Droid's
#             scanner sees the Dart packages)
#   SDK       /opt/android-sdk, NDK r28c (`ndk: r28c` in the F-Droid recipe;
#             Flutter's default NDK for the pinned version)
#
# Each ABI is built on its own, as each of the recipe's build blocks does.
# Leaves app-armeabi-v7a-release.apk, app-arm64-v8a-release.apk and
# app-x86_64-release.apk in build/app/outputs/flutter-apk/ of the checkout. Signing uses android/key.properties when it exists, as locally.
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
export PUB_CACHE="$project/.pub-cache"

rsync -a --delete --exclude .git --exclude .dart_tool --exclude build \
  --exclude .pub-cache ./ "$project/"
(
  cd "$project"
  flutter pub get --enforce-lockfile
  for platform in android-arm android-arm64 android-x64; do
    flutter build apk --release --split-per-abi --target-platform="$platform"
  done
)

mkdir -p build/app/outputs/flutter-apk
for abi in armeabi-v7a arm64-v8a x86_64; do
  cp "$project/build/app/outputs/flutter-apk/app-$abi-release.apk" build/app/outputs/flutter-apk/
done
