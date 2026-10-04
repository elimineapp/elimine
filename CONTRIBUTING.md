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
