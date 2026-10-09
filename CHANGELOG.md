# Changelog

## [0.3.0](https://github.com/elimineapp/elimine/compare/v0.2.0...v0.3.0) (2026-10-09)


### ⚠ BREAKING CHANGES

* the version code restarts at 1, below the 1000 and 2000 of 0.1.0 and 0.2.0, so those installs cannot be updated in place. Export the data, uninstall, install the new version and import the file.

### Features

* choose the interface language and theme in Settings ([e419019](https://github.com/elimineapp/elimine/commit/e419019e7bdc049e546435a49b53c53c57a91e01))
* endless history on Home and precise time since an intake ([84ae745](https://github.com/elimineapp/elimine/commit/84ae74511cbdd2eaefd1a3f9d14d1ad25701200f))
* reorder substances on Home by long-press and drag ([f5e2e26](https://github.com/elimineapp/elimine/commit/f5e2e26b8773e555b197b120688237509a3d7bd4))
* switch to the ink color theme and the night launcher icon ([33f37fb](https://github.com/elimineapp/elimine/commit/33f37fb8274c7a649be48c01d8df51c8762e5efb))


### Bug Fixes

* end chart axes at the tallest bar rounded to two digits ([ec29b17](https://github.com/elimineapp/elimine/commit/ec29b17f5c11174b2a3961d8a5259ef18d99a3c5))


### Build

* prepare reproducible builds and a store listing for F-Droid ([5572192](https://github.com/elimineapp/elimine/commit/5572192208cf6e7b3647e78d29572e63ae153a96))

## [0.2.0](https://github.com/elimineapp/elimine/compare/v0.1.0...v0.2.0) (2026-10-05)


### Features

* **analytics:** calendar weeks, months and years with paging ([38035bf](https://github.com/elimineapp/elimine/commit/38035bfb2a3bed529c745c43f0d35ccd32524269))
* animate navigation between tabs and screens ([db91894](https://github.com/elimineapp/elimine/commit/db918945c2d68ef210db0c0d6e32030305ba468d))
* edit or delete an intake from its entry ([3d9d331](https://github.com/elimineapp/elimine/commit/3d9d331545adb0e423db2e87d26294c5208e5ce5))
* move Settings into the bottom navigation ([f2868fb](https://github.com/elimineapp/elimine/commit/f2868fbfc9098288ad5dc108c1f8d285742362f9))
* tinted substance cards and a pull-up substance sheet ([b9aa4a3](https://github.com/elimineapp/elimine/commit/b9aa4a332d3e180a1b77fd56fdfecf8194df53a6))


### Bug Fixes

* **analytics:** wrap long metric values instead of squeezing the label ([6cdd7c8](https://github.com/elimineapp/elimine/commit/6cdd7c8b0230f82d41d798f4ff8b0995faa9dd19))
* polish labels and drop the "No dose" label ([0f72bb8](https://github.com/elimineapp/elimine/commit/0f72bb8422e1bf3bb7a5034871064de6c36f2aab))

## 0.1.0 (2026-10-04)


### Features

* **analytics:** add per-substance dose chart and cross-substance view ([1b4583c](https://github.com/elimineapp/elimine/commit/1b4583c8e677e4e33f9eda701d7229d704f2b595))
* **branding:** add Elimine launcher icon ([401b294](https://github.com/elimineapp/elimine/commit/401b294a4f802de564b8ec8c43565e767859bf10))
* delete substances and manage the archive ([8f1a172](https://github.com/elimineapp/elimine/commit/8f1a172c382b79c7f58d884d5cad4bb3e51784f4))
* export and import data backups ([4cbd03e](https://github.com/elimineapp/elimine/commit/4cbd03ee79379efc9d0f799be814cabca3535b3a))
* initial app with substances, quick logging and history ([912f276](https://github.com/elimineapp/elimine/commit/912f276b946753d71407c1bac658a31b1c37dadc))
* make the intake dose optional ([32c7b5d](https://github.com/elimineapp/elimine/commit/32c7b5decd2794fcccb4570fb449ca1b1ebaadc9))
* release signed apks through github releases ([231fb4d](https://github.com/elimineapp/elimine/commit/231fb4dc037258db33196886d6fdd51d552cb10b))


### Bug Fixes

* drop unused home_widget dependency ([49ceb5b](https://github.com/elimineapp/elimine/commit/49ceb5b19abe69060515ea4d1db2aa5630f30510))
