# Color theme

The app's light and dark color schemes, "Ink": near-neutral surfaces and one accent, the ink of the launcher icon. Substance colors live separately in `lib/core/appearance.dart`.

| File | Used for |
| --- | --- |
| `gen.py` | Builds both schemes from the palettes it defines and writes `lib/app/theme.dart` |

## Regenerating

`gen.py` needs Python 3 with [materialyoucolor](https://pypi.org/project/materialyoucolor/), a port of Material Color Utilities. It applies the same 2021 color spec as Flutter's `ColorScheme.fromSeed`:

```sh
cd design/theme
pip install materialyoucolor==3.0.4
python3 gen.py
dart format ../../lib/app/theme.dart
```

The output is already formatted, so `dart format` should report no changes.
