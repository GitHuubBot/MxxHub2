# MxxHub v0.3 testing

## Test 1 — library still works

Add a normal game folder and verify MxxHub detects the `.exe`, remembers the game, and shows its PE architecture/subsystem.

## Test 2 — x86-64 runtime bring-up

1. Copy `MxxHubRuntimeTestFolder.zip` to the iPhone Files app.
2. Unzip it.
3. Add the `MxxHubRuntimeTest` folder to MxxHub.
4. Select `MxxRuntime64Test.exe`.
5. Tap **Play**.

Expected v0.3 behavior: the full-screen **MxxHub Windows Runtime** opens and the WineGlass/blink engine attempts to load and execute the PE32+ x86-64 program. The tiny test has an entry point that simply returns 42; it is used to validate x64 engine bring-up before testing a game.

## Test 3 — Hollow Knight

Keep the Hollow Knight library entry you already created and press **Play**. The important difference from v0.2 is that MxxHub no longer rejects it merely because it is x86-64. It will hand `hollow_knight.exe` to the real experimental x64 backend.

Do not expect gameplay yet. Hollow Knight uses Unity/Direct3D and depends on Windows APIs and graphics support beyond the current WineGlass milestone. A dark runtime screen, early stop or missing-API failure is useful diagnostic information for the next version.

## If GitHub build fails

Open the failed Actions run. If the failure is in **Prepare WineGlass + Blink runtime**, copy the last 30–50 lines of that step. If it is in **Build unsigned device app**, download the `MxxHub-v0.3-build-log` artifact and send it back.
