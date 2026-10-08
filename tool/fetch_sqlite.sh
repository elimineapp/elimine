#!/usr/bin/env bash
# Downloads the SQLite amalgamation named in third_party/sqlite/VERSION and
# checks it against the hashes recorded there. package:sqlite3 compiles it into
# the app (hooks.user_defines in pubspec.yaml). Run by `task deps`; does nothing
# when the right sqlite3.c is already in place.
set -euo pipefail

cd "$(dirname "$0")/../third_party/sqlite"

value() { sed -n "s/^$1=//p" VERSION; }
hash() { python3 -c 'import hashlib,sys;print(hashlib.new(sys.argv[1],open(sys.argv[2],"rb").read()).hexdigest())' "$@"; }

url="$(value source)"
zip_sha3="$(value zip_sha3_256)"
c_sha256="$(value sqlite3_c_sha256)"

if [ -f sqlite3.c ] && [ "$(hash sha256 sqlite3.c)" = "$c_sha256" ]; then
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading SQLite $(value version) from $url"
curl -fsSL --retry 3 -o "$tmp/sqlite.zip" "$url"
if [ "$(hash sha3_256 "$tmp/sqlite.zip")" != "$zip_sha3" ]; then
  echo "SHA3-256 of $url does not match third_party/sqlite/VERSION" >&2
  exit 1
fi

unzip -q -j "$tmp/sqlite.zip" '*/sqlite3.c' -d "$tmp"
if [ "$(hash sha256 "$tmp/sqlite3.c")" != "$c_sha256" ]; then
  echo "SHA-256 of sqlite3.c does not match third_party/sqlite/VERSION" >&2
  exit 1
fi
mv "$tmp/sqlite3.c" sqlite3.c
