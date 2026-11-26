// Checks the layouts in Latam-Keyboard.bundle through macOS itself.
// Run it with tests/run.sh, which installs the bundle for the current user first
// and removes it afterwards. No Latin American keyboard is needed.
//
// For each layout it checks that macOS loads it, that its input source ID is stable,
// that its language is Spanish, and what a set of keys type. macOS only exposes the
// key data of a bundled layout while the layout is enabled, so each layout is enabled
// for a moment and disabled again. The current input source is never changed.

import Carbon
import Foundation

let bundleID = "com.github.neosergio.keyboardlayout.latam"

// Expected characters on key 10 (ISO key) and key 50, without and with Shift (nil = not checked).
// Type C's Shift pairing (| with >, < with °) is intentional: some gaming keyboards work that way.
// barOnOption: Option + key 50 types |, for keyboards without key 10 (like Apple's US keyboards),
// where B and C would otherwise have no way to type it. Idea from the PaoloLuciano fork.
let layouts: [(name: String, isoKeys: (plain: String, shift: String)?, barOnOption: Bool)] = [
    ("Latin American - A", ("<|", ">°"), false),
    ("Latin American - B", ("|<", "°>"), true),
    ("Latin American - C", ("|<", ">°"), true),
]

func expectedID(_ name: String) -> String {
    bundleID + ".keylayout." + name.filter { $0.isLetter || $0.isNumber || $0 == "-" }
}

func property(_ s: TISInputSource, _ key: CFString) -> AnyObject? {
    guard let p = TISGetInputSourceProperty(s, key) else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(p).takeUnretainedValue()
}
func string(_ s: TISInputSource, _ key: CFString) -> String { property(s, key) as? String ?? "" }

// An unfiltered list leaves out bundled layouts, so always ask for keyboard layouts.
func keyboardLayouts(includeAll: Bool) -> [TISInputSource] {
    let filter = [kTISPropertyInputSourceType as String: kTISTypeKeyboardLayout as String] as CFDictionary
    return TISCreateInputSourceList(filter, includeAll)?.takeRetainedValue() as? [TISInputSource] ?? []
}
func find(_ id: String) -> TISInputSource? {
    keyboardLayouts(includeAll: true).first { string($0, kTISPropertyInputSourceID) == id }
}
func enabledIDs() -> Set<String> {
    Set(keyboardLayouts(includeAll: false).map { string($0, kTISPropertyInputSourceID) })
}

// Types a sequence of (key code, modifiers) presses, carrying dead-key state between them.
func type(_ data: Data, _ presses: [(UInt16, Int)]) -> String {
    data.withUnsafeBytes { buf -> String in
        let layout = buf.bindMemory(to: UCKeyboardLayout.self).baseAddress!
        var dead: UInt32 = 0
        var out = ""
        for (code, mods) in presses {
            var len = 0
            var chars = [UniChar](repeating: 0, count: 4)
            UCKeyTranslate(layout, code, UInt16(kUCKeyActionDown), UInt32((mods >> 8) & 0xFF),
                           UInt32(LMGetKbdType()), 0, &dead, chars.count, &len, &chars)
            out += String(utf16CodeUnits: chars, count: len)
        }
        return out
    }
}

let caps = Int(alphaLock), cmd = Int(cmdKey), shift = Int(shiftKey), option = Int(optionKey)

func keyChecks(_ data: Data, isoKeys: (plain: String, shift: String)?, barOnOption: Bool) -> [(String, String, String)] {
    var checks: [(String, String, String)] = [
        ("ñ", type(data, [(41, 0)]), "ñ"),
        ("Shift+ñ", type(data, [(41, shift)]), "Ñ"),
        ("Caps Lock+ñ (#8)", type(data, [(41, caps)]), "Ñ"),
        ("´ then a, e, i, o, u",
         [0, 14, 34, 31, 32].map { type(data, [(33, 0), (UInt16($0), 0)]) }.joined(), "áéíóú"),
        ("Caps Lock: ´ then a", type(data, [(33, caps), (0, caps)]), "Á"),
        ("Cmd + + key (#6, #10, #11)", type(data, [(30, cmd)]), "+"),
        ("Cmd + - key (#6, #10, #11)", type(data, [(44, cmd)]), "-"),
        ("Cmd + 0", type(data, [(29, cmd)]), "0"),
        ("Cmd + c", type(data, [(8, cmd)]), "c"),
    ]
    if let iso = isoKeys {
        checks.append(("keys 10 and 50", type(data, [(10, 0), (50, 0)]), iso.plain))
        checks.append(("Shift: keys 10 and 50", type(data, [(10, shift), (50, shift)]), iso.shift))
        // Caps Lock must not move these keys (B had A's arrangement under Caps Lock).
        checks.append(("Caps Lock: keys 10 and 50", type(data, [(10, caps), (50, caps)]), iso.plain))
    }
    if barOnOption {
        checks.append(("Option + key 50", type(data, [(50, option)]), "|"))
        checks.append(("Caps Lock + Option + key 50", type(data, [(50, caps | option)]), "|"))
    }
    // Shift + Option + key 50 is the only direct way to type a backtick; keep it.
    checks.append(("Shift + Option + key 50", type(data, [(50, shift | option)]), "`"))
    return checks
}

// macOS may still be rebuilding its layout cache, so wait for the layouts to appear.
var loaded = false
for _ in 0..<20 {
    if layouts.allSatisfy({ find(expectedID($0.name)) != nil }) { loaded = true; break }
    Thread.sleep(forTimeInterval: 0.5)
}

let enabledBefore = enabledIDs()
var failures = 0
func fail(_ message: String) { print("     FAIL \(message)"); failures += 1 }

if !loaded { print("Not every layout loaded within 10 seconds; failures below show which.") }

for (name, isoKeys, barOnOption) in layouts {
    let id = expectedID(name)
    print(name)
    guard let src = find(id) else { fail("not loaded (expected ID \(id))"); continue }

    // The ID must not change once the name has been read (fixed in 1.1.1).
    _ = string(src, kTISPropertyLocalizedName)
    let idAfterName = string(src, kTISPropertyInputSourceID)
    if idAfterName != id { fail("ID changes to \(idAfterName) after reading the name") }

    // Word picks its spelling language from this (#1).
    let languages = property(src, kTISPropertyInputSourceLanguages) as? [String] ?? []
    if languages.first != "es" { fail("main language is \(languages.first ?? "none"), expected es") }

    let wasEnabled = enabledBefore.contains(id)
    if !wasEnabled { TISEnableInputSource(src) }
    defer { if !wasEnabled, let s = find(id) { TISDisableInputSource(s) } }

    guard let enabled = find(id), let raw = property(enabled, kTISPropertyUnicodeKeyLayoutData) else {
        fail("no key data"); continue
    }
    let checks = keyChecks(raw as! Data, isoKeys: isoKeys, barOnOption: barOnOption)
    for (what, got, want) in checks where got != want { fail("\(what): typed \"\(got)\", expected \"\(want)\"") }
    print("     \(checks.filter { $0.1 == $0.2 }.count)/\(checks.count) key checks passed")
}

// Disable anything from this bundle that the test enabled, even after a failure.
for s in keyboardLayouts(includeAll: false) {
    let id = string(s, kTISPropertyInputSourceID)
    if id.hasPrefix(bundleID) && !enabledBefore.contains(id) { TISDisableInputSource(s) }
}
if enabledIDs() != enabledBefore { fail("enabled input sources were not restored") }

print(failures == 0 ? "\nAll checks passed." : "\n\(failures) check(s) failed.")
exit(failures == 0 ? 0 : 1)
