# MxxHub v0.3.2 build fix

This revision fixes the GitHub Actions failure in **Prepare WineGlass + Blink runtime**.

Blink's configure script needs a `flock` executable on the macOS build host. Without one, it builds `flock` using the iPhoneOS cross-compiler and then tries to execute that iOS binary on macOS, which exits with code 1.

v0.3.2 installs Homebrew `flock` before running the cross-build and records the complete runtime preparation output in `runtime-prepare.log`. If the step still fails, GitHub uploads `MxxHub-v0.3.2-runtime-log` automatically.
