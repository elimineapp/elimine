# Tasks

## 1. Icon sources

- [x] 1.1 Copy `source/`, `ios/AppIcon.appiconset/` and `android/play-store-512.png` from the designer's export into `design/icon/` without `.DS_Store`; verify `find design/icon -type f` lists `gen.py`, both SVGs, the store image and the iOS icon set
- [x] 1.2 Add `design/icon/README.md` describing the files, the Android resources they produce and how to regenerate them with `gen.py`; ignore the script's `out/` directory in git; verify `git status` does not show `out/` after creating it

## 2. Launcher resources

- [x] 2.1 Copy the vector layers into `res/drawable/`, the adaptive definitions into `res/mipmap-anydpi-v26/` and the legacy `ic_launcher`/`ic_launcher_round` PNGs into every `res/mipmap-*` density; verify the layer PNG copies are not added
- [x] 2.2 Add `android:roundIcon="@mipmap/ic_launcher_round"` to the manifest; verify `flutter build apk --debug` succeeds

## 3. Verification

- [x] 3.1 Install on the phone (`task install DEVICE=10AFAU152N004SP`) and check the launcher icon: both leaves inside the mask, nothing clipped while pressing the icon, label "Elimine"
- [x] 3.2 On the Pixel emulator with Android 13+, enable themed icons and verify the leaves are tinted by the system; verify they are not clipped by the circular mask
- [x] 3.3 Run `task check` and verify formatting, analyzer and tests pass
