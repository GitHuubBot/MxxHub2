# MexxBox 0.1 — iOS Windows Game Library Prototype

MexxBox is a GameHub-style iOS launcher prototype for Windows game folders.

## What works in 0.1

- Dark GameHub-style game library
- Pick a folder from the iOS Files app
- Recursively scan that folder for `.exe` files
- Rank likely game executables above installers/uninstallers
- Choose the executable to use
- Save the folder with an iOS bookmark so the game stays in the library
- Per-game renderer, resolution, memory target, controller, touch-controls and launch-argument settings
- Remove a library entry without deleting the real game files
- Runtime status screen

## What does NOT work yet

`Play` does not execute Windows code in 0.1. It intentionally calls a runtime bridge that currently reports `Wine + Box64: not bundled`.

The next milestone is to connect the runtime bridge to:

1. Wine for Win32/Win64 APIs
2. Box64/x86 translation
3. JIT support on physical iOS hardware
4. DirectX translation / Metal rendering
5. Controller and touch input injection

Portal is the first planned 3D compatibility target, followed by Half-Life 2 and then Portal 2.

## Generate the Xcode project on a Mac

```bash
brew install xcodegen
xcodegen generate
open MexxBox.xcodeproj
```

Select your development Team under **Signing & Capabilities**, connect your iPhone, choose it as the run destination and press Run.

## Build an unsigned IPA on a Mac

```bash
./Scripts/build_ipa.sh
```

Output: `MexxBox-unsigned.ipa`

## Build from Windows using GitHub Actions

This repo contains `.github/workflows/build-ios.yml`.

1. Create a GitHub repository.
2. Upload/push this folder.
3. Open **Actions → Build MexxBox iOS → Run workflow**.
4. Download the `MexxBox-unsigned-ipa` artifact.
5. Sign/sideload the IPA with your normal iOS sideloading setup.

## First iPhone test

A fake folder is included at `SampleGames/PortalTest`. It contains a dummy `portal.exe`; it is only for testing the folder importer and EXE scanner.

Copy `PortalTest` to the iPhone Files app. In MexxBox:

1. Tap **Add Game**.
2. Pick `PortalTest`.
3. MexxBox should detect `portal.exe` and `setup.exe` and prefer `portal.exe`.
4. Tap **Add**.
5. Portal Test appears in **My Games**.
6. Open it, change settings and tap **Save Settings**.
7. Tap **Play**. Version 0.1 should show the expected `Windows runtime not bundled` message.

If all seven steps work, the complete iOS launcher/import/bookmark layer is working and the next work belongs in `Services/WindowsRuntime.swift`.
