#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="$(tr -d '[:space:]' < VERSION)"
OUT_DIR="$ROOT_DIR/dist"
mkdir -p "$OUT_DIR"

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG_BIN="$(xcrun --sdk iphoneos --find clang)"

SOURCES=(
  src/Core/NGEnvironment.m
  src/Core/NGPreferences.m
  src/Core/NGRuntimeBridge.m
  src/Dock/NGBadgeSync.m
  src/Dock/NGCapsuleDockView.m
  src/Dock/NGDockCoordinator.m
  src/Dock/NGNativeSolariumStyler.m
  src/Settings/NGSettingsViewController.m
  src/Settings/NGWeChatSettingsEntry.m
  src/NGEntry.m
)

DYLIB_PATH="$OUT_DIR/NaloiaGlass.dylib"
ZIP_NAME="NaloiaGlass-${VERSION}-dylib.zip"
ZIP_PATH="$OUT_DIR/$ZIP_NAME"

echo "[NaloiaGlass] Compiling $DYLIB_PATH (v$VERSION) against SDK: $SDK_PATH"

"$CLANG_BIN" \
  -arch arm64 \
  -isysroot "$SDK_PATH" \
  -miphoneos-version-min=16.0 \
  -dynamiclib \
  -fobjc-arc \
  -O2 \
  -Wall -Wextra -Werror \
  -Isrc/Core -Isrc/Dock -Isrc/Settings \
  -install_name "@rpath/NaloiaGlass.dylib" \
  -framework UIKit \
  -framework Foundation \
  -framework QuartzCore \
  -framework CoreFoundation \
  -framework CoreGraphics \
  -lobjc \
  "${SOURCES[@]}" \
  -o "$DYLIB_PATH"

codesign --force --sign - --timestamp=none "$DYLIB_PATH"
python3 "$ROOT_DIR/scripts/audit_macho.py" "$DYLIB_PATH"

(
  cd "$OUT_DIR"
  rm -f "$ZIP_NAME" SHA256SUMS.txt
  shasum -a 256 NaloiaGlass.dylib > SHA256SUMS.txt
  zip -9 "$ZIP_NAME" NaloiaGlass.dylib SHA256SUMS.txt
  shasum -a 256 "$ZIP_NAME" >> SHA256SUMS.txt
)

echo "[NaloiaGlass] Built $DYLIB_PATH and $ZIP_PATH successfully."
