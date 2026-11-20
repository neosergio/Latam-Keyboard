# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A set of macOS custom keyboard layouts (Apple `.keylayout` XML, typically edited with Ukelele) that map a Latin American physical keyboard on macOS. There is no build system, no code and no tests. Each layout is one `Latam_X.keylayout` file plus a matching `Latam_X.icns` icon with the **same basename**. macOS pairs them by filename, so keep the names in sync when you add or rename a layout.

## Distribution: Homebrew only

Homebrew is the only supported way for users to install these layouts: `brew install --cask neosergio/tap/latam-keyboard`. The cask lives in a separate repo, `neosergio/homebrew-tap` (`Casks/latam-keyboard.rb`). It downloads the GitHub tarball for a `vX.Y.Z` tag and installs the files into `/Library/Keyboard Layouts`, which needs sudo. Don't add manual `cp` install instructions to the README.

The cask names every file explicitly. **When you add, remove or rename a layout, update the variant list in the cask too.**

To release:
1. Tag `vX.Y.Z` here and push the tag.
2. In the tap, update `version`, and set `sha256` from `curl -sL https://github.com/neosergio/Latam-Keyboard/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256`.
3. Run `brew audit --cask --strict --online neosergio/tap/latam-keyboard`.

## Testing a layout change

A layout change can only be tested by installing it and logging out and back in. To try an unreleased edit, copy it into your user folder with `cp Latam_X.* ~/Library/Keyboard\ Layouts/`, log out and back in, and type. Delete the copy afterwards, or it will appear next to the copy Homebrew installed.

## Validate after editing

The files are XML 1.1 and use control-character references (`&#x0008;` for Backspace, `&#x001B;` for Escape, and so on). Plain `xmllint --noout` reports these as errors on every file, including files that work. To check for real syntax problems, filter that noise out:

```
xmllint --noout Latam_A.keylayout 2>&1 | grep error | grep -v 'invalid xmlChar value'   # no output = OK
```

A malformed `.keylayout` is ignored by macOS with no error message. The layout just disappears from Input Sources. Literal `<`, `>` and `&` in `output` attributes must be escaped (for example, `&#x003C;` for `<`). Don't "fix" the control-character references: macOS needs them.

## Layout variants

- **A**: for external keyboards. **B**: for built-in keyboards. **C**: for some gaming keyboards.
  - The main difference is that the ISO key (code `10`) and the `|°` key (code `50`) are swapped: A has `<` on 10 and `|` on 50, while B and C have the reverse.
- **`_white`**: the same layout as its base, with a white icon for dark mode. Its `.keylayout` should differ from the base only in the `name` and `id` attributes. **When you change a base layout, apply the same change to its `_white` twin.**
- **D**: a contributed layout for one specific keyboard with unusual Command and `+` behavior. It was generated separately (different `group`/`id`, multiple `<layout>` entries per keyboard type, different `modifierMap` and `keyMapSet` ids, space indentation). Don't assume its structure matches A, B or C.

## `.keylayout` structure (A/B/C)

- `modifierMap id="48"` defines keyMap indices 0–7: 0 = none, 1 = Shift, 2 = Caps, 3 = Option, 4 = Shift+Option, 5 = Caps+Option, 6 = Command (any combination), 7 = Control.
- `keyMapSet id="312"` holds one `<keyMap>` per index. Each one maps a virtual key `code` to either a literal `output` or an `action` (dead keys).
- `<actions>` and `<terminators>` implement the dead keys (accents such as ´ ¨ ^ `). A key whose `action="aNN"` sends its output through these state machines, so a change to an accented key's behavior usually means editing `<actions>`, not the keyMap.
- **Every layout needs its own `id`** on `<keyboard>`. They use `group="126"` (Unicode) with negative IDs: A to C_white are -5001 to -5006, and D is -17832. When macOS finds a duplicate ID, it silently reassigns one, and which layout gets which ID depends on load order (this caused issue #9). The `name` attribute is the name shown in Input Sources and must also be unique.
