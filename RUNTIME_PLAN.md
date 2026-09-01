# Runtime roadmap

## v0.2 — achieved in this source package

Windows PE32 parser → entry-point mapping → tiny x86 interpreter → on-device correctness test.

## v0.3

Integrate an existing mature x86 execution core rather than expanding the tiny interpreter. Current candidates:

- WineGlass: Windows PE + Win32 API translation + Metal compositor.
- Box64 iOS: embedded x86_64 translation foundation; pair with Wine/WoW64 later.

Target: run a simple real Windows GUI program that calls Win32 APIs.

## v0.4

Wine/WoW64 + graphics bridge, file mappings, audio and controller input.

## Source Engine milestone

1. Half-Life 2 / Source DX9 launcher starts.
2. Portal reaches menu.
3. Portal enters a map.
4. Controller + touch mapping.
5. Portal 2 after the Portal path is stable.
