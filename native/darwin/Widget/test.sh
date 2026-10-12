#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUT="$ROOT/build/native/darwin/widget-tests"
mkdir -p "$OUT"
xcrun swiftc -swift-version 6 -parse-as-library \
  -framework WidgetKit "$ROOT/native/darwin/Sources/WidgetABI.swift" \
  "$ROOT/native/darwin/Widget/Snapshot.swift" "$ROOT/native/darwin/Widget/SnapshotTests.swift" -o "$OUT/snapshot-tests"
"$OUT/snapshot-tests" "$ROOT/internal/widget/testdata/snapshot-v1.json"
python3 "$ROOT/native/darwin/Widget/check-localizations.py"
bash -n "$ROOT/native/darwin/Widget/build.sh" "$ROOT/native/darwin/Widget/embed.sh" "$ROOT/native/darwin/Widget/preview.sh"
