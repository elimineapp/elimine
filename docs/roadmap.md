# Roadmap

Items are listed in the order they will be done. Each one becomes an OpenSpec change (`openspec/changes/`) when work on it starts; requirements live in `openspec/specs/`.

## 1. Releases and publishing

Discussion first, no implementation yet.

- Channels: Google Play (check its policy for substance-related apps), F-Droid, RuStore, APKs in GitHub Releases.
- Signing key: creation, storage, backup (losing it means the app can no longer be updated).
- Versioning (`version` in `pubspec.yaml`) and a changelog.
- CI: build and `task check` on every push, release builds on tags.
- Privacy policy (required by Google Play), store icon and screenshots.
- Signing key owner, store account and support e-mail under the Elimine identity.
