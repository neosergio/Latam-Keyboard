# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A set of macOS custom keyboard layouts (Apple `.keylayout` XML, typically edited with Ukelele) that map a Latin American physical keyboard on macOS. There is no build system; the only code is the test in `tests/` and the icon generator in `tools/`.

Everything ships as one keyboard layout bundle, `Latam-Keyboard.bundle`:
- `Contents/Resources/` holds each layout as a `Latam_X.keylayout` file plus a matching `Latam_X.icns` icon with the **same basename**. macOS pairs them by filename, so keep the names in sync when you add or rename a layout.
- `Contents/Info.plist` has one `KLInfo_<name>` entry per layout (see below).

There are three layouts, A, B and C. Version 1.2.0 removed Type D and the White variants; don't bring them back (see "Layout variants").

## `Info.plist` rules

Each `KLInfo_<name>` entry needs `<name>` to match the `name` attribute in the `.keylayout` exactly. **When you add, remove or rename a layout, update its entry**, and run `plutil -lint` on the plist afterwards. Bump `CFBundleVersion` and `CFBundleShortVersionString` to match each release tag.

- **`TISInputSourceID` must be `<CFBundleIdentifier>.keylayout.<name with everything except letters, digits and `-` removed>`**, for example `...latam.keylayout.LatinAmerican-B`. macOS reports that automatic ID until something reads the layout's name, and only then switches to the plist's ID. If the two differ, the same layout has two IDs, and an added layout can go missing (fixed in 1.1.1).
- **`TISIntendedLanguage` must be `es`, not `es-419`.** Word picks its spelling language from the active layout's language. It doesn't recognize `es-419` and leaves the text with no language at all, so Spanish spell checking doesn't apply and accented words get flagged (issue #1, fixed in 1.2.1). Apple's own Latin American layout declares `es`. A loose `.keylayout` can't declare a language at all, which is why the layouts ship as a bundle.
- **Don't set `TISIconIsTemplate`.** Since macOS 26 the menu bar is transparent and tinted by the wallpaper, so a fixed black or white icon disappears on one kind of background. A template icon fixes the menu bar, but in the input-source badge next to the text cursor macOS draws it in the badge's own blue, so the selected layout's badge looks empty (seen on macOS 27 in 1.1.2 and 1.1.3). Instead, every layout uses a fixed black silhouette with a thin white outline, made by `tools/outline-icon.swift` from the old black icon (the comment at the top of that file says how to run it). It's visible over light and dark wallpapers and in the badge.

Changing a layout's `TISInputSourceID` or its `name` makes macOS treat it as a new layout: users have to remove and re-add it in Input Sources. Avoid it, and when it can't be avoided, say so in the README and in the cask's `caveats`. Changing the language or the icon doesn't affect IDs.

## Distribution: Homebrew only

Homebrew is the only supported way for users to install these layouts: `brew install --cask neosergio/tap/latam-keyboard`. The cask lives in a separate repo, `neosergio/homebrew-tap` (`Casks/latam-keyboard.rb`). It downloads the GitHub tarball for a `vX.Y.Z` tag and installs the bundle into `/Library/Keyboard Layouts`, which needs sudo; it also clears the layout caches on install and uninstall. Don't add manual `cp` install instructions to the README.

To release:
1. Bump the version in `Info.plist`, commit, tag `vX.Y.Z` here and push the branch and the tag.
2. Download the tarball and check its contents before using it. GitHub may return 404 for a minute or two after the tag is pushed; retry.
3. In the tap, pull first (it often has newer commits for other formulae), update `version`, and set `sha256` from `curl -sL https://github.com/neosergio/Latam-Keyboard/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256`.
4. Run `brew style` and `brew audit --cask --strict --online neosergio/tap/latam-keyboard`. Homebrew's local copy of the tap is a separate clone, so update it before auditing.
5. If layouts were removed or IDs changed, update the cask's `caveats` and the README's upgrade section.

## Testing a layout change

Run the automated test after any change to a `.keylayout` or `Info.plist`:

```
tests/run.sh
```

No Latin American keyboard and no logout are needed. The script compiles `tests/layouttest.swift`, installs the bundle in `~/Library/Keyboard Layouts`, clears the per-user layout cache, and asks macOS directly about each layout:
- that it loads;
- that its input source ID doesn't change after its name is read;
- that its main language is `es`;
- what keys type, through `UCKeyTranslate`, including keys 10 and 50 with and without Shift and Caps Lock, Caps Lock + `ñ`, accents, and Command shortcuts;
- that every printable ASCII character can be typed (the characters that matter for programming), and in B and C also without key 10.

macOS only provides a bundled layout's key data while the layout is enabled, so the test enables each one for a moment and disables it again. It never changes the current input source, and it removes the bundle and clears the cache on exit. **When you fix a key bug, add a check for it in `keyChecks`.**

### When the layouts are already installed with Homebrew

`tests/run.sh` refuses to run if Latam layouts are already installed, because a second copy would load with the same IDs. To test the installed release instead, compile and run the test on its own; it checks whatever layouts macOS has loaded:

```
swiftc -O tests/layouttest.swift -o /tmp/layouttest && /tmp/layouttest
```

Check first which version is installed (`brew list --cask --versions latam-keyboard`) and whether it matches the repo (`diff -rq "/Library/Keyboard Layouts/Latam-Keyboard.bundle" Latam-Keyboard.bundle`).

To try an unreleased change on a Mac that has the Homebrew install, don't copy the bundle into `~/Library`. Copy the changed files over the installed ones with `sudo cp`, clear both layout caches (`sudo rm -f /System/Library/Caches/com.apple.IntlDataCache.le*` and `rm -f "$(getconf DARWIN_USER_CACHE_DIR)"com.apple.IntlDataCache.le*`), and log out and back in. The next `brew upgrade` or `brew reinstall --cask latam-keyboard` puts the released files back.

### Talking to macOS's input source API (TIS)

- macOS caches the layouts it found. After changing files, delete the per-user cache (`com.apple.IntlDataCache.le*` in `$(getconf DARWIN_USER_CACHE_DIR)`), or you'll be testing the old files. The first query after clearing it can come back incomplete while the cache rebuilds; retry for a few seconds, as the test does.
- An unfiltered `TISCreateInputSourceList(nil, …)` leaves out bundled layouts and is inconsistent between calls. Always filter by `kTISPropertyInputSourceType` = `kTISTypeKeyboardLayout`.
- Neither the icon nor `TISIconIsTemplate` can be read through the public API.

### What has to be checked by eye

Some things only show on screen. Any keyboard works for these, since Keyboard Viewer (in the input menu) shows what each key types:
- **Keyboard Viewer** without modifiers, with Caps Lock, and with Command held. The screenshot shortcut also uses Command, so take that one with a timer (`screencapture -T 5 file.png`). An orange outline on the `´` key isn't a stuck key: it marks a dead (accent) key. With Command held it types `´` directly and isn't outlined.
- **The icon** in the menu bar over a light wallpaper and a dark one.
- **The input badge** next to the text cursor: in TextEdit, switch layouts with Ctrl+Space or the 🌐 key. It only lasts a second, so use `screencapture -T 3`.
- **Word's spelling language:** ask Word through AppleScript, for example `tell application "Microsoft Word" to get language ID of word 2 of active document`. `language none` means Word didn't recognize the layout's language. Compare with a line typed with Apple's own Latin American layout.

The README's screenshots live in `docs/images/`. Don't link images from external hosts.

## Validate after editing

The files are XML 1.1 and use control-character references (`&#x0008;` for Backspace, `&#x001B;` for Escape, and so on). Plain `xmllint --noout` reports these as errors on every file, including files that work. To check for real syntax problems, filter that noise out:

```
xmllint --noout Latam-Keyboard.bundle/Contents/Resources/Latam_A.keylayout 2>&1 | grep error | grep -v 'invalid xmlChar value'   # no output = OK
```

A malformed `.keylayout` is ignored by macOS with no error message. The layout just disappears from Input Sources. Literal `<`, `>` and `&` in `output` attributes must be escaped (for example, `&#x003C;` for `<`). Don't "fix" the control-character references: macOS needs them.

## Layout variants

- **A**: for external keyboards. **B**: for built-in keyboards. **C**: for some gaming keyboards.
  - The main difference is that the ISO key (code `10`, next to the left Shift key) and the key below Esc (code `50`) are swapped: A has `<` on 10 and `|` on 50, while B and C have the reverse.
  - With Shift, A types `>` on 10 and `°` on 50, and B types `°` on 10 and `>` on 50. **C intentionally pairs them differently** (`|` with `>` on 10, `<` with `°` on 50), because some gaming keyboards are labeled that way. Don't "fix" it.
  - Keyboards without key 10 (Apple's US keyboards, the Logitech MX Keys Mini) can't type whatever only lives there. For them, B and C also put `|` on Option + key 50 and Caps Lock + Option + key 50 (since 1.3.0, idea from the PaoloLuciano fork, which used Control). A isn't meant for those keyboards: it would need both `<` and `>`, and Shift + Option + key 50 must stay `` ` ``, the only direct way to type a backtick. `tests/run.sh` checks both.
  - **When you swap keys 10 and 50, swap them in every key map** (plain, Shift, Caps Lock, Option and so on), not only plain and Shift. B's Caps Lock map was left with A's arrangement for years (fixed in 1.1.3, found in Keyboard Viewer).
- Version 1.2.0 removed Type D (a workaround for the Command bug fixed in 1.0.3, which had become the same as A except with Option) and the White variants of A, B and C (replaced by the outlined icon).

## `.keylayout` structure

- `modifierMap id="48"` defines keyMap indices 0–7: 0 = none, 1 = Shift, 2 = Caps, 3 = Option, 4 = Shift+Option, 5 = Caps+Option, 6 = Command (any combination), 7 = Control.
- **Map 6 (Command) must mirror map 0**, with each dead-key action replaced by the plain character it types, so that shortcuts such as Cmd+`+` and Cmd+`-` use the characters printed on the keys. It used to follow a US keyboard, which broke these shortcuts (issues #6, #10 and #11). When you change a key in map 0, update map 6 to match. Map 7 (Control) sends control codes on the same keys as Apple's layouts; that's correct.
- `keyMapSet id="312"` holds one `<keyMap>` per index. Each one maps a virtual key `code` to either a literal `output` or an `action` (dead keys).
- `<actions>` and `<terminators>` implement the dead keys (accents such as ´ ¨ ^ `). A key whose `action="aNN"` sends its output through these state machines, so a change to an accented key's behavior usually means editing `<actions>`, not the keyMap.
- **Every layout needs its own `id`** on `<keyboard>`. They use `group="126"` (Unicode) with negative IDs: A is -5001, B is -5003 and C is -5005. Don't reuse -5002, -5004, -5006 (the removed White variants) or -17832 (the removed Type D) for a new layout. When macOS finds a duplicate ID, it silently reassigns one, and which layout gets which ID depends on load order (this caused issue #9). The `name` attribute is the name shown in Input Sources and must also be unique.
