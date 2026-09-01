# MxxHub runtime plan

## v0.3 — current

Library -> PE32/PE32+ -> WineGlass engine -> blink x86/x86-64 -> Win32 thunks -> Metal Win32 compositor.

Goal: execute real 32-bit/64-bit Windows programs directly from a saved MxxHub library entry and render basic Win32 UI.

## v0.4

- improve runtime logging inside MxxHub
- mouse/keyboard/game-controller forwarding
- working directory and game-folder filesystem compatibility
- audio bridge
- more Win32 APIs

## v0.5 graphics milestone

- Direct3D translation/bridge
- fullscreen framebuffer path
- first Source-engine 3D test
- Portal / Half-Life 2 compatibility work

## Later

- Hollow Knight / Unity-specific work
- Steam client experiments
- per-game compatibility presets
- cover art / metadata
- touch-control editor
