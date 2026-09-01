# MexxBox v0.2 — Windows PE/x86 bring-up

MexxBox is a GameHub-style iOS launcher aimed at running imported Windows game folders.

## New in v0.2

- Validates real Windows MZ/PE executables.
- Detects x86, x86_64 and ARM64 PE architecture.
- Shows Windows GUI/console subsystem and entry point.
- Includes a tiny correctness-first x86 interpreter.
- Can execute the included `MexxRuntimeTest.exe` PE32 entry point on iPhone.
- Expected test result: **EAX = 42**.

This is deliberately not described as Portal support. Normal Windows games contain thousands of x86/x64 instructions and Win32/DirectX calls. Those require the next backend: WineGlass/Box64 plus a graphics layer.

## Build

Use the included GitHub Actions workflow. The unsigned IPA appears under the successful workflow run's **Artifacts** section.
