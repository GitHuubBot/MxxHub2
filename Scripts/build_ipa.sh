#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install it with: brew install xcodegen"
  exit 1
fi

xcodegen generate
rm -rf build Payload MexxBox-unsigned.ipa

xcodebuild \
  -project MexxBox.xcodeproj \
  -scheme MexxBox \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CONFIGURATION_BUILD_DIR="$PWD/build" \
  build

mkdir Payload
cp -R build/MexxBox.app Payload/
/usr/bin/zip -qry MexxBox-unsigned.ipa Payload

echo "Created: $PWD/MexxBox-unsigned.ipa"
