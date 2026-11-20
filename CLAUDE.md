# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A set of macOS custom keyboard layouts (Apple `.keylayout` XML, typically edited with Ukelele) that map a Latin American physical keyboard on macOS. There is no build system; the only code is the test in `tests/` and the icon generator in `tools/`.

Everything ships as one keyboard layout bundle, `Latam-Keyboard.bundle`:
- `Contents/Resources/` holds each layout as a `Latam_X.keylayout` file plus a matching `Latam_X.icns` icon with the **same basename**. macOS pairs them by filename, so keep the names in sync when you add or rename a layout.
- `Contents/Info.plist` has one `KLInfo_<name>` entry per layout, where `<name>` must match the `name` attribute in the `.keylayout` exactly. Each entry sets `TISIntendedLanguage` to `es-419` and a `TISInputSourceID`. **Don't set `TISIconIsTemplate`.** Since macOS 26 the menu bar is transparent and tinted by the wallpaper, so a fixed black or white icon disappears on one kind of background. A template icon fixes the menu bar, but macOS draws it in the badge's own blue inside the input-source badge next to the text cursor, so the selected layout's badge looks empty (seen on macOS 27 in 1.1.2 and 1.1.3). Instead, A, B, C and D use a fixed black silhouette with a thin white outline, made by `tools/outline-icon.swift` from the old black icon (see the comment at the top of that file for how to run it). It's visible in the menu bar over light and dark wallpapers and in the badge. The White variants predate it and are no longer needed. Neither the icon nor the template flag can be checked through the public TIS API, so `tests/run.sh` can't check icons; check them by eye. **The ID must be `<CFBundleIdentifier>.keylayout.<name with everything except letters, digits and `-` removed>`**, for example `...latam.keylayout.LatinAmerican-B-White` or `...latam.keylayout.LatinD`. macOS reports that automatic ID until something reads the layout's name, and only then switches to the plist's ID. If the two differ, the same layout has two IDs, and an added layout can go missing (fixed in 1.1.1). A loose `.keylayout` can't declare a language, so macOS reported none and Word fell back to English spelling (issue #1). **When you add, remove or rename a layout, update its `KLInfo_` entry**, and run `plutil -lint` on the plist afterwards.
- Bump `CFBundleVersion` and `CFBundleShortVersionString` in `Info.plist` to match each release tag.

## Distribution: Homebrew only

Homebrew is the only supported way for users to install these layouts: `brew install --cask neosergio/tap/latam-keyboard`. The cask lives in a separate repo, `neosergio/homebrew-tap` (`Casks/latam-keyboard.rb`). It downloads the GitHub tarball for a `vX.Y.Z` tag and installs the files into `/Library/Keyboard Layouts`, which needs sudo. Don't add manual `cp` install instructions to the README.

To release:
1. Tag `vX.Y.Z` here and push the tag.
2. In the tap, update `version`, and set `sha256` from `curl -sL https://github.com/neosergio/Latam-Keyboard/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256`.
3. Run `brew audit --cask --strict --online neosergio/tap/latam-keyboard`.

## Testing a layout change

Run the automated test after any change to a `.keylayout` or `Info.plist`:

```
tests/run.sh
```

No Latin American keyboard and no logout are needed. The script compiles `tests/layouttest.swift`, installs the bundle in `~/Library/Keyboard Layouts`, clears the per-user layout cache, and asks macOS directly about each layout:
- that it loads;
- that its input source ID doesn't change after its name is read;
- that its main language is `es`;
- what keys type, through `UCKeyTranslate`.

macOS only provides a bundled layout's key data while the layout is enabled, so the test enables each one for a moment and disables it again. It never changes the current input source, and it removes the bundle and clears the cache on exit. It refuses to run if Latam layouts are already installed in either Keyboard Layouts folder. **When you fix a key bug, add a check for it in `keyChecks`.**

A real typing test still needs installing the bundle (`cp -R Latam-Keyboard.bundle ~/Library/Keyboard\ Layouts/`), logging out and back in, and typing. Delete the copy afterwards.

## Validate after editing

The files are XML 1.1 and use control-character references (`&#x0008;` for Backspace, `&#x001B;` for Escape, and so on). Plain `xmllint --noout` reports these as errors on every file, including files that work. To check for real syntax problems, filter that noise out:

```
xmllint --noout Latam-Keyboard.bundle/Contents/Resources/Latam_A.keylayout 2>&1 | grep error | grep -v 'invalid xmlChar value'   # no output = OK
```

A malformed `.keylayout` is ignored by macOS with no error message. The layout just disappears from Input Sources. Literal `<`, `>` and `&` in `output` attributes must be escaped (for example, `&#x003C;` for `<`). Don't "fix" the control-character references: macOS needs them.

## Layout variants

- **A**: for external keyboards. **B**: for built-in keyboards. **C**: for some gaming keyboards.
  - The main difference is that the ISO key (code `10`) and the `|°` key (code `50`) are swapped: A has `<` on 10 and `|` on 50, while B and C have the reverse.
  - With Shift, A types `>` on 10 and `°` on 50, and B types `°` on 10 and `>` on 50. **C intentionally pairs them differently** (`|` with `>` on 10, `<` with `°` on 50), because some gaming keyboards are labeled that way. Don't "fix" it.
  - **When you swap keys 10 and 50, swap them in every key map** (plain, Shift, Caps Lock, Option and so on), not only plain and Shift. B's Caps Lock map was left with A's arrangement for years (fixed in 1.1.3). `tests/run.sh` checks keys 10 and 50 without modifiers, with Shift and with Caps Lock.
- **`_white`**: the same layout as its base, with a white icon for dark mode. Its `.keylayout` should differ from the base only in the `name` and `id` attributes. **When you change a base layout, apply the same change to its `_white` twin.**
- **D**: deprecated, to be removed in 1.2.0. It was contributed (PR #7) as a workaround for the Command bug fixed in 1.0.3 (#6, #10, #11): Apple's Latin American layout with `<` and `|` swapped. It now types the same as A without modifiers, with Shift, Caps Lock and Command, and differs only in the Option maps, which follow Apple's. When removing it, delete its two files, its `KLInfo_` entry and its line in `tests/layouttest.swift`. It was generated separately (different `group`/`id`, multiple `<layout>` entries per keyboard type, different `modifierMap` and `keyMapSet` ids, space indentation). Don't assume its structure matches A, B or C.

## `.keylayout` structure (A/B/C)

- `modifierMap id="48"` defines keyMap indices 0–7: 0 = none, 1 = Shift, 2 = Caps, 3 = Option, 4 = Shift+Option, 5 = Caps+Option, 6 = Command (any combination), 7 = Control.
- **Map 6 (Command) must mirror map 0**, with each dead-key action replaced by the plain character it types, so that shortcuts such as Cmd+`+` and Cmd+`-` use the characters printed on the keys. It used to follow a US keyboard, which broke these shortcuts (issues #10 and #11). When you change a key in map 0, update map 6 to match.
- `keyMapSet id="312"` holds one `<keyMap>` per index. Each one maps a virtual key `code` to either a literal `output` or an `action` (dead keys).
- `<actions>` and `<terminators>` implement the dead keys (accents such as ´ ¨ ^ `). A key whose `action="aNN"` sends its output through these state machines, so a change to an accented key's behavior usually means editing `<actions>`, not the keyMap.
- **Every layout needs its own `id`** on `<keyboard>`. They use `group="126"` (Unicode) with negative IDs: A to C_white are -5001 to -5006, and D is -17832. When macOS finds a duplicate ID, it silently reassigns one, and which layout gets which ID depends on load order (this caused issue #9). The `name` attribute is the name shown in Input Sources and must also be unique.
