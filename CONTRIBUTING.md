# Contributing

## Language

Everything in the repository is written in English: code, comments, specs, docs and commit messages. The Russian UI translation lives in `lib/l10n/app_ru.arb`.

## Specs

Requirements live in `openspec/specs/`. Behavior changes start as an OpenSpec change in `openspec/changes/` and are archived into the specs when done.

## Commits

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<optional scope>): <summary>

<optional body>
```

- Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style`, `revert`.
- Scope is optional and names the area, e.g. `analytics`, `db`, `l10n`.
- The summary is imperative and lowercase, with no trailing period: `feat(analytics): add busiest weekday metric`.
- A breaking change adds `!` after the type or scope and a `BREAKING CHANGE:` footer.

Run `task check` before committing.

## Releases

Releases are cut by [release-please](https://github.com/googleapis/release-please) from the commit messages, so the commit type decides what users see:

- `feat` raises the minor version, `fix` and `perf` the patch version (before 1.0.0, a breaking change raises the minor version too).
- `feat`, `fix`, `perf` and `revert` appear in `CHANGELOG.md`; `docs`, `test`, `ci`, `build`, `chore`, `refactor` and `style` do not.

Every push to `main` updates an open release pull request with the next version and its changelog entry. Merging it tags `vX.Y.Z` and creates the GitHub release; the release workflow then runs the full check on the tag, builds the APK, signs it with the release key, verifies the certificate against `.github/release-cert.sha256` and attaches `elimine-X.Y.Z.apk`. If that build fails after the release exists, fix the cause and run the Release workflow manually with the tag to attach the APK.

Do not edit the version in `pubspec.yaml` by hand. The Android version code is derived from it.

The release key is never committed. Locally, release builds use it only when `android/key.properties` points at it; otherwise they are signed with the debug key.
