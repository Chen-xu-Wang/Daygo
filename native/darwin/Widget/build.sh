#!/usr/bin/env bash
# Build only a development extension. No signing, install or release packaging.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUT="$ROOT/build/native/darwin/widget"
BUNDLE="$OUT/DaygoTimeline.appex"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
for arch in arm64 x86_64; do
  xcrun swiftc -swift-version 6 -parse-as-library -O -application-extension \
    -target "$arch-apple-macos14.0" -sdk "$SDK" \
    -module-cache-path "$OUT/$arch/module-cache" \
    -framework SwiftUI -framework WidgetKit -framework Foundation \
    "$ROOT/native/darwin/Widget/Snapshot.swift" \
    "$ROOT/native/darwin/Widget/TimelineWidget.swift" \
    "$ROOT/native/darwin/Widget/WidgetMain.swift" -o "$OUT/DaygoTimeline-$arch"
done
xcrun lipo -create "$OUT/DaygoTimeline-arm64" "$OUT/DaygoTimeline-x86_64" -output "$BUNDLE/Contents/MacOS/DaygoTimeline"
cp -R "$ROOT/native/darwin/Widget/Resources/" "$BUNDLE/Contents/Resources/"
cp "$ROOT/native/darwin/Widget/Info.plist" "$BUNDLE/Contents/Info.plist"
plutil -lint "$BUNDLE/Contents/Info.plist"
printf 'Unsigned development extension: %s\n' "$BUNDLE"
