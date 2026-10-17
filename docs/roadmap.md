# Roadmap

Items are listed in the order they will be done. Each one becomes an OpenSpec change (`openspec/changes/`) when work on it starts; requirements live in `openspec/specs/`.

## 1. More distribution channels

APKs are published on GitHub Releases (see CONTRIBUTING.md). The build is reproducible from the tag, the F-Droid recipe is in `fdroid/` and the store listing with screenshots is in `fastlane/`. What is left for F-Droid, in order:

- [ ] Release 0.3.1, the first with one APK per ABI, and check that the F-Droid check in the release workflow passes for all three.
- [ ] Open a merge request to fdroiddata with `fdroid/com.elimine.elimine.yml` filled in for 0.3.1, and get its pipeline green.
- [ ] Once F-Droid publishes the app, list it first under Install in the README with the F-Droid badge, and remove this list.

Next:

- Google Play: check its policy for substance-related apps, developer account under the Elimine identity, privacy policy, closed testing, store listing.
- RuStore.
- Support e-mail, and the store graphics Google Play needs beyond the icon and screenshots in `fastlane/`.
