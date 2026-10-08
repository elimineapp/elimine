# SQLite

`package:sqlite3` compiles SQLite into the app through its build hook (`hooks.user_defines.sqlite3` in `pubspec.yaml`), so release builds do not download a prebuilt library: F-Droid requires every binary to be built from source.

The source is the unmodified SQLite amalgamation. It is not committed: `tool/fetch_sqlite.sh` (run by `task deps`) downloads the archive named in `VERSION` from sqlite.org, checks it against the SHA3-256 that sqlite.org publishes, and puts `sqlite3.c` here after checking its SHA-256. SQLite is in the public domain (https://sqlite.org/copyright.html).

The version is the one the prebuilt binaries of the locked `package:sqlite3` use, so the app behaves the same as with them.

## Updating

1. Find the SQLite version of the new `package:sqlite3` in its `CHANGELOG.md`.
2. On https://sqlite.org/download.html, take the URL and SHA3-256 of `sqlite-amalgamation-XXYYZZ00.zip` and put them into `VERSION` with the new version.
3. Remove `sqlite3.c`, set `sqlite3_c_sha256` to the SHA-256 of the `sqlite3.c` in that archive (`shasum -a 256`), and run `tool/fetch_sqlite.sh` to check both hashes.
4. Check that the hook still accepts `source: source` with `path` in the package's `doc/hook.md`, then run `task check` and build a release APK.
