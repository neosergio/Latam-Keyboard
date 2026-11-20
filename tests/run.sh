#!/bin/sh
# Installs Latam-Keyboard.bundle for the current user, runs tests/layouttest.swift
# against it, and removes it again. Needs Xcode or the Command Line Tools (swiftc).
set -eu

repo=$(cd "$(dirname "$0")/.." && pwd)
user_dir="$HOME/Library/Keyboard Layouts"
installed="$user_dir/Latam-Keyboard.bundle"
cache_dir=$(getconf DARWIN_USER_CACHE_DIR)

# Don't run next to a real install: the test copy would clash with it.
for dir in "$user_dir" "/Library/Keyboard Layouts"; do
  if ls "$dir"/Latam* >/dev/null 2>&1; then
    echo "Latam layouts are already installed in $dir." >&2
    echo "Uninstall them first (brew uninstall --cask latam-keyboard), then run this again." >&2
    exit 2
  fi
done

work=$(mktemp -d)
clear_cache() { rm -f "$cache_dir"/com.apple.IntlDataCache.le*; }
cleanup() {
  rm -rf "$installed" "$work"
  clear_cache
}
trap cleanup EXIT

swiftc -O "$repo/tests/layouttest.swift" -o "$work/layouttest"

mkdir -p "$user_dir"
cp -R "$repo/Latam-Keyboard.bundle" "$installed"
clear_cache

# macOS logs harmless messages to stderr; only show them if the test fails.
if ! "$work/layouttest" 2>"$work/stderr.log"; then
  cat "$work/stderr.log" >&2
  exit 1
fi
