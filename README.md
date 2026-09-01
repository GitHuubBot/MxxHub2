# MxxHub v0.3 — experimental Windows runtime

MxxHub is a GameHub-style iOS library for importing Windows game folders and launching their `.exe` files.

## What changed in v0.3

- App/product name changed from **MexxBox** to **MxxHub**.
- Keeps the previous `com.mexx.mexxbox` bundle ID deliberately, so installing v0.3 over v0.2 updates the same app and migrates the saved library to the new MxxHub storage name.
- Keeps the folder library, PE inspection, game settings and security-scoped bookmarks from v0.2.
- Replaces the tiny x86 bring-up interpreter in the Play path with an **experimental WineGlass + blink backend**.
- The GitHub Actions build fetches WineGlass and blink, builds the iOS ARM64 blink static runtime, then compiles them into MxxHub.
- Adds a full-screen Metal runtime surface for Win32 windows/dialogs.
- Adds a real x86-64 PE test executable in `MxxHubRuntimeTestFolder.zip`.

## Reality check

This is a runtime-integration milestone, not a claim that Hollow Knight or Portal is compatible yet. WineGlass currently provides PE32/PE32+ loading, x86/x86-64 execution and a growing Win32 layer. Direct3D game rendering and many game-specific APIs are still incomplete, so complex games may stop, remain on a dark screen, or only reach early initialization.

## Build

The included GitHub Actions workflow is the normal build path:

1. Upload the contents of this folder to the repository root.
2. Open **Actions**.
3. Run **Build MxxHub iOS v0.3**.
4. Download the `MxxHub-v0.3-unsigned-ipa` artifact.
5. Sign/sideload the IPA as before.

The build requires internet access because the workflow fetches the current WineGlass and blink source trees.

## Upstream

MxxHub v0.3 experimentally integrates:

- WineGlass by Contonion — Apache-2.0
- blink by Justine Tunney and contributors — upstream license applies

See `THIRD_PARTY.md`.
