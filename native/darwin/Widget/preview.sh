#!/usr/bin/env bash
# Offline SwiftUI layout preview with anonymous activity, not a system widget.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUT="$ROOT/build/native/darwin/widget-preview"
APP="$OUT/Preview.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp -R "$ROOT/native/darwin/Widget/Resources/" "$APP/Contents/Resources/"
xcrun swiftc -swift-version 6 -parse-as-library \
  "$ROOT/native/darwin/Widget/Snapshot.swift" \
  "$ROOT/native/darwin/Widget/TimelineWidget.swift" \
  "$ROOT/native/darwin/Widget/Preview.swift" -o "$APP/Contents/MacOS/Preview"
"$APP/Contents/MacOS/Preview" "$OUT"
printf 'Anonymous light/dark layout previews: %s/{small,medium,large}[-dark].png\n' "$OUT"
