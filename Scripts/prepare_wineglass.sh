#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXT="$ROOT/External"
WG="$EXT/WineGlass"
BLINK="$EXT/blink"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CC="$(xcrun --sdk iphoneos -f clang)"
AR="$(xcrun --sdk iphoneos -f ar)"

rm -rf "$WG" "$BLINK"
mkdir -p "$EXT"

echo "==> Fetching WineGlass engine"
git clone --depth 1 https://github.com/Contonion/WineGlass.git "$WG"

echo "==> Fetching blink x86/x64 emulator"
git clone --depth 1 https://github.com/jart/blink.git "$BLINK"

# The WineGlass integration currently uses blink in interpreter mode. This is
# deliberately the conservative bring-up path for sideloaded iOS builds.
cd "$BLINK"
# WineGlass documents this iOS baseline config before running configure.
cp config.h.ios config.h
./configure \
  CC="$CC" \
  AR="$AR" \
  CFLAGS="-g -O2 -arch arm64 -isysroot $SDK -miphoneos-version-min=17.0" \
  --disable-threads \
  --disable-sockets \
  --disable-jit

echo "==> Building blink static archive"
if command -v gmake >/dev/null 2>&1; then
  gmake -j"$(sysctl -n hw.ncpu)" o//blink/blink.a
else
  make -j"$(sysctl -n hw.ncpu)" o//blink/blink.a
fi

mkdir -p "$WG/Vendor/blink/lib"
cp "$BLINK/o//blink/blink.a" "$WG/Vendor/blink/lib/blink.a"

echo "==> Building WineGlass/blink bridge object"
"$CC" -c -std=c11 -g -O2 -arch arm64 \
  -isysroot "$SDK" \
  -miphoneos-version-min=17.0 \
  -D_FILE_OFFSET_BITS=64 -D_DARWIN_C_SOURCE -DTARGET_OS_IPHONE=1 \
  -isystem "$SDK/usr/include" \
  -I"$BLINK" -include "$BLINK/config.h" \
  "$WG/Vendor/blink/wg_blink_impl.c" \
  -o "$WG/Vendor/blink/lib/wg_blink_impl.o"

# The MxxHub app supplies its own SwiftUI lifecycle and runtime controller.
# Remove WineGlass' standalone UIApplication entry points but keep its Metal
# view implementation and all PE/CPU/Win32/graphics engine code.
rm -f \
  "$WG/Sources/App/main.m" \
  "$WG/Sources/App/WGAppDelegate.m" "$WG/Sources/App/WGAppDelegate.h" \
  "$WG/Sources/App/WGSceneDelegate.m" "$WG/Sources/App/WGSceneDelegate.h" \
  "$WG/Sources/App/WGConsoleOverlay.m" "$WG/Sources/App/WGConsoleOverlay.h" \
  "$WG/Sources/App/Info.plist" "$WG/Sources/App/WineGlass.entitlements"

cat > "$EXT/UPSTREAM_VERSIONS.txt" <<VERSIONS
WineGlass: $(git -C "$WG" rev-parse HEAD)
blink: $(git -C "$BLINK" rev-parse HEAD)
Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
VERSIONS

echo "==> WineGlass runtime prepared for MxxHub"
