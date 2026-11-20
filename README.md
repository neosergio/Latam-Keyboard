# Latam-Keyboard
A Mac Keyboard Layout for latin american keyboards

![Latin American layout](http://i.imgur.com/5zm6nHB.png)

## Install

Install with [Homebrew](https://brew.sh):

```
brew install --cask neosergio/tap/latam-keyboard
```

Homebrew will ask for your password, because the layouts are installed for all users in `/Library/Keyboard Layouts`.

Log out and back in, then add the layout under **System Settings > Keyboard > Input Sources > Edit > +**. Search for "Latin American". The layouts are marked as Latin American Spanish, so apps like Word use Spanish spelling while you type with them. The screenshots below are from an older macOS version:

![Latin American - step 01](http://i.imgur.com/SUiyeLT.png)

![Latin American - step 02](http://i.imgur.com/iHXGlM1.png)

![Latin American - step 03](http://i.imgur.com/zkXihp7.png)

To update to a new version:

```
brew upgrade --cask latam-keyboard
```

### Upgrading from version 1.0.x

Version 1.1.0 changed how the layouts are packaged, and macOS sees them as new layouts. After `brew upgrade`, remove the old Latin American layouts from **System Settings > Keyboard > Input Sources**, log out and back in, and add them again.

### Upgrading from a manual install

Earlier versions of this README said to copy the files into `~/Library/Keyboard Layouts` by hand. If you did that, remove those copies before or after installing with Homebrew, so that each layout shows up only once:

```
rm ~/Library/Keyboard\ Layouts/Latam_*
```

## Uninstall

1. Remove the layout from **System Settings > Keyboard > Input Sources**.
2. Run `brew uninstall --cask latam-keyboard`.
3. Log out and back in.

## Which layout to choose

**There are several versions. Try them and choose the one that works for you.**

The icon of Types A, B, C and D adapts to the menu bar on its own: white over a dark background, black over a light one. That matters since macOS 26, where the menu bar is transparent and its color depends on your wallpaper, not on light or dark mode. Types A, B and C also come in a _White_ version with a fixed white icon. It's meant for older macOS versions, or if the adaptive icon doesn't show up for you.

- _**Type A**_: Frequently used for external keyboards.

![Built into keyboard](http://i.imgur.com/65X5vVI.jpg)

- _**Type B**_: Frequently used for built-in keyboards.

![Built into keyboard](http://i.imgur.com/Cphc5Py.jpg)

- _**Type C**_: Some gaming keyboards work better with this layout, just test it :)

- _**Type D**_ (**deprecated, will be removed in version 1.2.0**): it was added because Command shortcuts like Cmd+`+` didn't work in the other layouts. That was fixed in version 1.0.3, and Type D now types the same as Type A except with Option. If you use Type D, switch to Type A.

### Contribute ###

Feel free to contribute, adapt or improve this layout and share it with the community.

Before sending a pull request, run `tests/run.sh`. It checks every layout through macOS itself, including what the keys type, without needing a Latin American keyboard or a logout. You need Xcode or the Command Line Tools.
