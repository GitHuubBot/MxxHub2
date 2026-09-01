# MexxBox v0.2 test

1. Build the unsigned IPA in GitHub Actions and sideload it as before.
2. Put `MexxRuntimeTestFolder.zip` in Files on the iPhone and extract it.
3. In MexxBox tap **+** and select the extracted `MexxRuntimeTestFolder`.
4. The app should identify `MexxRuntimeTest.exe` as `x86 (32-bit) • Windows Console`.
5. Add it to the library.
6. Open it and press **Play / Runtime Test**.
7. Success is:

   `x86 executable ran`

   and a message showing:

   `EAX returned 42`

That proves a real Windows PE file was parsed and its x86 entry-point instructions executed by MexxBox on iOS.

## Trying a real game EXE

You can add Portal/HL2 folders now. MexxBox should identify the executable architecture. Pressing Play will probably stop at the first x86 instruction not supported by the tiny bring-up interpreter. That is expected. Do not treat that as a Portal compatibility failure; the next step is replacing the tiny interpreter with the WineGlass/Box64 backend and Win32/graphics support.
