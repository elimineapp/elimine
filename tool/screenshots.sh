#!/usr/bin/env bash
# Store and README screenshots, taken on an emulator with demo data.
#
#   tool/screenshots.sh prepare             fresh install, demo backup, clean status bar
#   tool/screenshots.sh capture NAME THEME  save the screen as NAME.png (THEME: light or dark)
#
# DEVICE picks the emulator (default: the first one running). Real devices are
# refused: prepare uninstalls the app, which would erase its data.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v adb >/dev/null; then
  PATH="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools:$PATH"
fi

device="${DEVICE:-$(adb devices | awk '/^emulator-/ { print $1; exit }')}"
if [ -z "$device" ]; then
  echo "No emulator running; start one with 'task emulator'." >&2
  exit 1
fi
if [ "$(adb -s "$device" shell getprop ro.kernel.qemu | tr -d '\r')" != 1 ] &&
  [ "$(adb -s "$device" shell getprop ro.boot.qemu | tr -d '\r')" != 1 ]; then
  echo "$device is not an emulator; screenshots are only taken on emulators." >&2
  exit 1
fi
adb_() { adb -s "$device" "$@"; }

demo() {
  adb_ shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null
}

case "${1:-}" in
  prepare)
    flutter build apk --release
    adb_ uninstall com.elimine.elimine >/dev/null 2>&1 || true
    adb_ install build/app/outputs/flutter-apk/app-release.apk

    # The app's clock matches the status bar: today at 9:41, when the
    # emulator image allows root (Google APIs images do, Play images do not).
    backup="$(mktemp)"
    if adb_ root >/dev/null 2>&1 && adb_ wait-for-device &&
      [ "$(adb_ shell id -u | tr -d '\r')" = 0 ]; then
      adb_ shell settings put global auto_time 0
      adb_ shell date "$(date +%m%d)0941$(date +%Y).00" >/dev/null
      dart run tool/demo_backup.dart "$backup" "$(date +%Y-%m-%d)T09:41"
    else
      echo "No root on $device: the app uses the real time." >&2
      dart run tool/demo_backup.dart "$backup"
    fi
    adb_ push "$backup" /sdcard/Download/elimine-demo.json >/dev/null 2>&1
    rm -f "$backup"

    adb_ shell settings put global sysui_demo_allowed 1
    demo enter
    demo clock -e hhmm 0941
    demo battery -e level 100 -e plugged false
    demo network -e wifi show -e level 4 -e fully true
    demo network -e mobile hide
    demo notifications -e visible false
    echo "Ready. Import Download/elimine-demo.json in Settings → Import, then capture."
    ;;
  capture)
    name="${2:?NAME is required, e.g. 1_home}"
    case "${3:-}" in
      light) dir=fastlane/metadata/android/en-US/images/phoneScreenshots ;;
      dark) dir=docs/screenshots/dark ;;
      *)
        echo "THEME must be light or dark." >&2
        exit 1
        ;;
    esac
    mkdir -p "$dir"
    adb_ exec-out screencap -p >"$dir/$name.png"
    echo "$dir/$name.png"
    ;;
  *)
    sed -n '2,8p' "$0" >&2
    exit 64
    ;;
esac
