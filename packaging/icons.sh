#!/usr/bin/env bash
# Regenerate every app and tray icon from original SuiteDock SVG geometry (MIT OR Apache-2.0).
#
# - App icon (Dock, taskbar, Start menu, Linux menus, installers): the blue mark, which is also
#   generated from our original dock/play geometry.
# - Tray: the black mark as the macOS menu-bar template; the blue mark on Windows, Linux and BSD.
#
# Needs: resvg (brew install resvg / cargo install resvg). The .ico and .icns are packed by
# `cargo xtask ico` / `cargo xtask icns`, so this runs on any OS. The outputs are committed, so
# packaging (and the Rust build, which include_bytes!s some of them) never needs these tools.
#
#   packaging/icons.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT/assets/app-icon"
BRAND="$ROOT/docs/brand"
SVG="$BRAND/suitedock-mark.svg"
ID="io.github.ripdzl.suitedock"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v resvg >/dev/null || { echo "error: resvg not found (brew install resvg)" >&2; exit 1; }

MAC="$SVG"
FLAT="$SVG"

render() { resvg -w "$2" -h "$2" "$1" "$3" </dev/null; }

render "$MAC" 1024 "$DIR/suitedock-1024.png"

# Linux hicolor theme.
for s in 16 24 32 48 64 128 256 512; do
  mkdir -p "$DIR/hicolor/${s}x${s}/apps"
  render "$FLAT" "$s" "$DIR/hicolor/${s}x${s}/apps/$ID.png"
done
mkdir -p "$DIR/hicolor/scalable/apps"
cp "$SVG" "$DIR/hicolor/scalable/apps/$ID.svg"
cp "$SVG" "$DIR/suitedock.svg"

# Windows .ico.
ICO_PNGS=()
for s in 16 20 24 32 40 48 64 128 256; do
  render "$FLAT" "$s" "$TMP/ico-$s.png"
  ICO_PNGS+=("$TMP/ico-$s.png")
done
(cd "$ROOT" && cargo run -q -p xtask -- ico "$DIR/suitedock.ico" "${ICO_PNGS[@]}")

# macOS .icns.
ICNS_PNGS=()
for s in 16 32 64 128 256 512 1024; do
  render "$MAC" "$s" "$TMP/icns-$s.png"
  ICNS_PNGS+=("$TMP/icns-$s.png")
done
(cd "$ROOT" && cargo run -q -p xtask -- icns "$DIR/suitedock.icns" "${ICNS_PNGS[@]}")

# Tray icons: the black mark is the macOS menu-bar template (44 px = 22 pt @2x; macOS tints it);
# the blue one is for the Windows notification area and Linux/BSD status notifiers.
render "$BRAND/suitedock-mark-black.svg" 44 "$BRAND/suitedock-mark-black-44.png"
render "$BRAND/suitedock-mark.svg" 64 "$BRAND/suitedock-mark-64.png"
echo "icons written to $DIR"

# Category icons and installer wordmark use the same original vector sources.
for file in "$ROOT"/assets/app-icons/*.svg; do render "$file" 128 "${file%.svg}.png"; done
resvg "$BRAND/suitedock-logo.svg" "$BRAND/suitedock-logo.png" </dev/null
resvg "$BRAND/suitedock-logo-white.svg" "$BRAND/suitedock-logo-white.png" </dev/null
