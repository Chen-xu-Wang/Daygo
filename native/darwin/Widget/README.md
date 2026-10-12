# Daygo macOS timeline widget

WidgetKit + SwiftUI extension for macOS 14+. Small / medium / large show the
latest 1 / 3 / 8 cards of the logical day, newest first. Large uses a compact
start-time row; small / medium show both start and end. All UI copy has nine
localizations. Titles are private activity data displayed on the desktop.

## Without a developer team

```bash
native/darwin/Widget/test.sh
native/darwin/Widget/build.sh
native/darwin/Widget/preview.sh
```

These run anonymous Go/Swift snapshot and localization checks and compile a
universal unsigned development extension under `build/native/darwin/widget/`.
The preview command renders anonymous SwiftUI layout PNGs for all three sizes;
it does not run inside WidgetKit. These commands do not install, sign, publish or prove that the system widget gallery works.
Run `CGO_ENABLED=0 go test ./internal/widget ./internal/app` for the Go side.

## With a developer team

Build a **fresh disposable development Daygo.app** with the current Go/native
sources first (`native/darwin/build.sh` then the existing Wails development build
entry). An old app binary does not contain the publisher. Do not use the installed
recording app or a release candidate for this experiment.

```bash
native/darwin/Widget/embed.sh /absolute/path/to/development/Daygo.app \
  YOURTEAMID 'Apple Development: Your Name (YOURTEAMID)'
```

Replace `YOURTEAMID` with your actual ten-character team ID. The script compiles,
sets a team-prefixed macOS App Group, preserves existing host entitlements,
checks the extension signer team, embeds the extension and signs inside out.
It requires an Apple-issued identity for that team, and deliberately fails for
ad-hoc/self-signed identities with no matching team. Existing bundle ID is kept.
This development entry is separate from release packaging; release integration,
provisioning/notarization and real upgrade identity still require review.

Launch the development app once. Right-click the desktop → Edit Widgets → Daygo
→ choose a size. macOS decides actual refresh timing; Daygo requests a reload
only when visible data changes. The app must run to publish new activity.

## Acceptance still required

Use anonymous activity for initial native integration. Verify gallery registration,
shared container 0600 and atomic writes, all sizes and both appearances, language
persistence after restart, edit/delete reflection while the window is closed,
4 AM expiry, app restart/exit, malformed input fallback and signed upgrade.
No real screen recordings or database contents should be added to fixtures.

Disable by removing the embedded extension and `DaygoWidgetAppGroup` from a
fresh development app, then restore its normal signature. The shared JSON can
be removed; the database has no migration or new writer.

See [design decision](../../../docs/decisions/timeline-macos-widget.md).
