# Spacer

Empty space for the macOS menu bar. Add as many gaps as you like, give each its own width, and drag them between your icons to sort the icons into groups.

- Any number of gaps, each moved on its own with ⌘-drag.
- A gap is invisible until you point at it. Then a faint frame shows where it is and how wide it is.
- Click a gap to change its width, add another gap next to it or remove it.
- A wide gap pushes the icons to its left towards the camera housing or off the screen, which hides icons that cannot be hidden any other way.
- Nothing but the gaps takes up room: Spacer has no menu bar icon of its own and no Dock icon.
- No permissions, no network code. English and Swedish.

Requires macOS 26 or later.

## Using Spacer

The first time Spacer starts it adds one gap, shows its frame for a few seconds and opens the settings window.

| To | Do this |
|---|---|
| Move a gap | Hold ⌘ and drag it in the menu bar, like any other icon |
| See where a gap is | Point at it |
| Change the width | Click the gap and drag the slider, from 4 to 400 points |
| Add a gap | Click a gap and choose New Gap. It appears just to the left of the one you clicked |
| Remove a gap | Click it and choose Remove This Gap |
| Open the settings | Click a gap and choose Settings…, or open Spacer again from Spotlight or Finder |

The settings window lists every gap in the order they have in the menu bar, from left to right, with a width slider and a remove button for each. Pointing at a row shows the frame of that gap in the menu bar. The window also has the switch for opening Spacer at login, which turns itself on the first time Spacer runs from the Applications folder.

Good to know:

- macOS puts its usual spacing around a gap, as it does around an icon: 8 points on each side. A gap with the width 24 therefore moves its neighbours 40 points apart, and the narrowest gap takes 20.
- When the menu bar is full, macOS hides the items furthest to the left, gaps included. A gap that is not in view is marked in the settings window, where you can still make it narrower or remove it.
- A gap added from the settings window is placed furthest to the right among the icons of your apps, next to Control Center, where it is always in view.
- When the last gap is removed the settings window opens, since nothing of the app is otherwise on screen.
- Quitting Spacer takes the gaps out of the menu bar. They come back in the same places the next time it starts.

## What is stored

The list of gaps, with an identifier and a width for each, is kept in the app's preferences (`com.freberdev.spacer`). The place of each gap in the menu bar is kept by macOS in the same preferences. Removing a gap removes what was stored about it. Nothing leaves your Mac.

Quit Spacer, then

```bash
defaults delete com.freberdev.spacer
```

starts over from nothing. That includes the note that opening at login has been turned on once, so the next start from the Applications folder turns it on again.

## Building

Spacer is a Swift package with no dependencies. You need Xcode 26 or later.

```bash
scripts/test.sh
```

```bash
scripts/build-app.sh --install
```

The script builds `build/Spacer.app`, signs it and, with `--install`, copies it to `/Applications`. Without `--install` it only builds. A running Spacer is quit first and is not started again; open it yourself afterwards. The script refuses to replace an app named Spacer that is not this one.

Spacer has been run on macOS 27.2 on Apple silicon. It is built for macOS 26 and for Intel as well, but has not been tried on either.

### Signing

`scripts/build-app.sh` signs with the identity in the environment variable `SPACER_SIGN_IDENTITY`, or else the first line of a file named `.signing-identity` in the project folder. With neither, the app is signed ad hoc, which works but makes macOS treat every build as a new app.

```bash
security find-identity -v -p codesigning
```

lists the identities on your Mac. `.signing-identity` is ignored by git.

### A disk image for others

```bash
scripts/build-dmg.sh
```

builds a universal app (Apple silicon and Intel), signs it with a Developer ID certificate, and produces `build/Spacer-<version>.dmg`, notarized by Apple.

- The certificate comes from `SPACER_RELEASE_IDENTITY` or the first line of `.release-identity`.
- The notarization credentials come from a keychain profile named in `SPACER_NOTARY_PROFILE` or the first line of `.notary-profile`. Create the profile once with `xcrun notarytool store-credentials`.

Both files are ignored by git. Without a notary profile the image is signed but not notarized.

### Development options

Two command-line options help when working on Spacer:

```bash
build/Spacer.app/Contents/MacOS/Spacer -printLayout YES -openMenu YES
```

`-printLayout` prints the id, width and position of every gap each time something changes, and whether the gap is in view. `-openMenu` opens the menu of the first gap shortly after start.

A build started this way shares its preferences with an installed Spacer. Only one copy runs at a time: a second one asks the first to show its settings and quits.

### Layout

- `Sources/SpacerCore` holds the logic: the list of gaps, the width limits, storage, the order of the gaps and where a new one goes. It does not use AppKit and is covered by the tests in `Tests/SpacerCoreTests`.
- `Sources/SpacerApp` is the app: one status item per gap, the frame, the menu and the settings window.
- `Resources` holds `Info.plist`, the icon and the English and Swedish strings.
- `scripts/make-icon.swift` draws the icon: `swift scripts/make-icon.swift`.

A gap is an empty `NSStatusItem` with an autosave name of its own, which is what lets macOS remember the place of each gap separately. A new status item without a stored place is put at the far left, where a full menu bar hides it, so Spacer writes the place of a new gap before it creates the item.

## License

MIT. See [LICENSE](LICENSE).
