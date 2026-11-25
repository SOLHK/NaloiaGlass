#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="$(tr -d '[:space:]' < VERSION)"
DYLIB_PATH="$ROOT_DIR/dist/NaloiaGlass.dylib"
DEB_NAME="com.solhk.naloiaglass_${VERSION}_iphoneos-arm64.deb"
DEB_PATH="$ROOT_DIR/dist/$DEB_NAME"

if [[ ! -f "$DYLIB_PATH" ]]; then
  echo "Error: $DYLIB_PATH not found. Run scripts/build_dylib.sh first." >&2
  exit 1
fi

python3 "$ROOT_DIR/scripts/package_deb.py" "$DYLIB_PATH" "$DEB_PATH"
(
  cd "$ROOT_DIR/dist"
  shasum -a 256 "$DEB_NAME" >> SHA256SUMS.txt
)
