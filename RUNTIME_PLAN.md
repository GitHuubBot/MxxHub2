# Runtime integration plan

The launcher calls one interface: `WindowsRuntimeProtocol`.

## Stage A — tiny Win32 program

Replace `StubWindowsRuntime` with a real runtime implementation that can start a tiny x86/x64 PE executable. Keep graphics simple and prove filesystem access first.

## Stage B — JIT / translation

Integrate an x86/x64-to-ARM64 translator. The runtime must expose a clear JIT status because performance without JIT is expected to be insufficient for Source-engine games.

## Stage C — Wine

Bundle a Wine build compatible with the chosen translator and initialize one prefix per compatibility profile. Map the selected iOS game folder into a stable Wine drive path.

## Stage D — graphics

Start with Direct3D 9 because Portal and Half-Life 2 are early targets. Add the DirectX-to-Vulkan/Metal path only after basic Win32 execution is reliable.

## Stage E — Source preset

Create a Source Engine profile:

- 1280x720 default
- controller enabled
- conservative memory target
- D3D9 path
- predefined launch-argument options

Then test in this order:

1. Half-Life 2 benchmark/menu
2. Portal menu
3. Portal gameplay
4. HL2 gameplay
5. Portal 2 menu
6. Portal 2 gameplay
