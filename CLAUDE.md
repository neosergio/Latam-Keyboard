# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A set of macOS custom keyboard layouts (Apple `.keylayout` XML, typically edited with Ukelele) that map a Latin American physical keyboard on macOS. There is no build system, no code and no tests. Each layout is one `Latam_X.keylayout` file plus a matching `Latam_X.icns` icon with the **same basename**. macOS pairs them by filename, so keep the names in sync when you add or rename a layout.

## Install / try a layout

```
cp -v Latam*.* ~/Library/Keyboard\ Layouts/
```

Then log out and back in (or restart) and add the layout under System Settings > Keyboard > Input Sources. A layout change can't be tested any other way. If you change a file that is already installed, copy it again and log out again.

## Validate after editing

The files are XML 1.1 and use control-character references (`&#x0008;` for Backspace, `&#x001B;` for Escape, and so on). Plain `xmllint --noout` reports these as errors on every file, including files that work. To check for real syntax problems, filter that noise out:

```
xmllint --noout Latam_A.keylayout 2>&1 | grep error | grep -v 'invalid xmlChar value'   # no output = OK
```

A malformed `.keylayout` is ignored by macOS with no error message. The layout just disappears from Input Sources. Literal `<`, `>` and `&` in `output` attributes must be escaped (for example, `&#x003C;` for `<`). Don't "fix" the control-character references: macOS needs them.

## Layout variants

- **A**: for external keyboards. **B**: for built-in keyboards. **C**: for some gaming keyboards.
  - The main difference is that the ISO key (code `10`) and the `|°` key (code `50`) are swapped: A has `<` on 10 and `|` on 50, while B and C have the reverse.
- **`_white`**: the same layout as its base, with a white icon for dark mode. Its `.keylayout` should differ from the base only in the `name` attribute. **When you change a base layout, apply the same change to its `_white` twin.**
- **D**: a contributed layout for one specific keyboard with unusual Command and `+` behavior. It was generated separately (different `group`/`id`, multiple `<layout>` entries per keyboard type, different `modifierMap` and `keyMapSet` ids, space indentation). Don't assume its structure matches A, B or C.

## `.keylayout` structure (A/B/C)

- `modifierMap id="48"` defines keyMap indices 0–7: 0 = none, 1 = Shift, 2 = Caps, 3 = Option, 4 = Shift+Option, 5 = Caps+Option, 6 = Command (any combination), 7 = Control.
- `keyMapSet id="312"` holds one `<keyMap>` per index. Each one maps a virtual key `code` to either a literal `output` or an `action` (dead keys).
- `<actions>` and `<terminators>` implement the dead keys (accents such as ´ ¨ ^ `). A key whose `action="aNN"` sends its output through these state machines, so a change to an accented key's behavior usually means editing `<actions>`, not the keyMap.
- All A/B/C files share `id="5006"`. The `name` attribute on `<keyboard>` is the name shown in Input Sources.
