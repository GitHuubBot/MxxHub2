# MexxBox 0.1 Test Checklist

## Simulator test

- App launches
- Library empty state appears
- Settings shows `Wine + Box64 / not bundled`
- Add Game opens the document picker
- A selected test folder is scanned for `.exe` files
- Adding a selected executable creates a game tile
- Relaunching the app keeps the library entry
- Editing settings and saving survives relaunch
- Removing the game removes only the library entry

## Physical iPhone test

Physical hardware is the important target because the future emulator/JIT/Metal runtime cannot be validated in the iOS Simulator.

### Test data

Copy `SampleGames/PortalTest` into `On My iPhone` using Files, iCloud Drive, AirDrop, USB file sharing, or another file provider.

Expected scan order:

1. `portal.exe`
2. `bin/setup.exe` (de-prioritized)

### Expected Play behavior in 0.1

Pressing Play must show a message saying the launcher selected the executable but Wine/Box64 is not bundled yet. That is a PASS for milestone 0.1.

## Milestone 0.2 acceptance test

The first real runtime acceptance target should be a tiny Win32 test executable rather than Portal:

- Start a simple x86 Windows `.exe`
- Show a native Windows message/window through Wine
- Read files from the selected game folder
- Exit cleanly without crashing iOS

Only after that should Portal/Source Engine work begin.
