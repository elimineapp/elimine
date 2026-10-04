# App icon

Two leaves, light and dark, on a green-to-blue gradient.

| File | Used for |
| --- | --- |
| `source/icon.svg` | Master artwork, 1024 px square |
| `source/icon-rounded-preview.svg` | Preview with rounded corners |
| `source/gen.py` | Generates every output below from the shapes and colors it defines |
| `android/play-store-512.png` | Play Store listing |
| `ios/AppIcon.appiconset/` | iOS app icon, kept for a future iOS build |

The Android launcher resources live in `android/app/src/main/res/`:

- `drawable/ic_launcher_{background,foreground,monochrome}.xml`: adaptive icon layers as vector drawables; the monochrome layer is the themed icon on Android 13+.
- `mipmap-anydpi-v26/ic_launcher{,_round}.xml`: adaptive icon definitions.
- `mipmap-*/ic_launcher{,_round}.png`: square and round icons for Android 7.x.

## Regenerating

`gen.py` needs Python with [CairoSVG](https://cairosvg.org/) (and the Cairo library, `brew install cairo` on macOS). It writes into `out/` in the current directory:

```sh
cd design/icon/source
pip install cairosvg
python3 gen.py
```

Then copy from `out/`:

- `android/res/drawable/*.xml`, `android/res/mipmap-anydpi-v26/*.xml` and `android/res/mipmap-*/ic_launcher{,_round}.png` into `android/app/src/main/res/`; the `ic_launcher_{background,foreground,monochrome}.png` files are not needed, the vector layers replace them;
- `android/play-store-512.png`, `ios/` and `source/` back into this directory.
