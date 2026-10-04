# Roadmap

Items are listed in the order they will be done. Each one becomes an OpenSpec change (`openspec/changes/`) when work on it starts; requirements live in `openspec/specs/`.

## 1. Data export and import

The only way to keep history across devices or reinstalls: Android cloud backup is disabled.

- Format: a single JSON file with a format version. It holds substances (archived included), doses and intakes (soft-deleted included, so an import does not bring deleted entries back). An intake's `amount` and a substance's `unit` may be empty (`null` and `""`).
- Export: an `elimine-YYYY-MM-DD.json` file saved through the system file picker or shared.
- Import: pick a file, check its version, preview "N substances, M intakes", confirm. Records match by UUID, so importing the same file twice creates no duplicates.
- Entry point: the Home header (the settings entry the spec already anticipates).
- To decide: whether import merges with existing data or replaces it.
- Tests: export then import into an empty database gives the same data; a repeated import adds no duplicates; an unknown format version is rejected.

## 2. Releases and publishing

Discussion first, no implementation yet.

- Channels: Google Play (check its policy for substance-related apps), F-Droid, RuStore, APKs in GitHub Releases.
- Signing key: creation, storage, backup (losing it means the app can no longer be updated).
- Versioning (`version` in `pubspec.yaml`) and a changelog.
- CI: build and `task check` on every push, release builds on tags.
- Privacy policy (required by Google Play), store icon and screenshots.
- Signing key owner, store account and support e-mail under the Elimine identity.
