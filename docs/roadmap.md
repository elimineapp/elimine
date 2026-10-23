# Roadmap

Items are listed in the order they will be done. Each one becomes an OpenSpec change (`openspec/changes/`) when work on it starts; requirements live in `openspec/specs/`.

## 1. More distribution channels

APKs are published on GitHub Releases (see CONTRIBUTING.md). The build is reproducible from the tag, the F-Droid recipe is in `fdroid/` and the store listing with screenshots is in `fastlane/`. What is left for F-Droid, in order:

- [x] Release 0.3.1, the first with one APK per ABI, and check that the F-Droid check in the release workflow passes for all three.
- [ ] Reopen [fdroiddata!52959](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52959) after 2026-12-29, with the recipe in the fork updated to the latest release and its pipeline green. F-Droid closed it because an app has to be developed for at least three months before inclusion; the build and the reproducibility check passed.
- [ ] Once F-Droid publishes the app, list it first under Install in the README with the F-Droid badge, and remove this list.

Next:

- Google Play: check its policy for substance-related apps, developer account under the Elimine identity, privacy policy, closed testing, store listing.
- RuStore.
- Support e-mail, and the store graphics Google Play needs beyond the icon and screenshots in `fastlane/`.
