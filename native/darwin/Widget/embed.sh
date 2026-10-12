#!/usr/bin/env bash
# Explicit opt-in for a disposable development app. Does not generate releases.
set -euo pipefail
if [[ $# != 3 ]]; then
  printf 'Usage: %s /path/to/development/Daygo.app TEAM_ID "Apple Development: ..."\n' "$0" >&2
  exit 1
fi
APP="$1"
TEAM="$2"
IDENTITY="$3"
[[ "$TEAM" =~ ^[A-Z0-9]{10}$ ]] || { echo 'Invalid team ID' >&2; exit 1; }
PLIST="$APP/Contents/Info.plist"
[[ -f "$PLIST" ]] || { echo 'Missing application Info.plist' >&2; exit 1; }
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST")"
[[ "$BUNDLE_ID" == 'io.github.jwz-git.Daygo' ]] || { echo 'Unexpected host bundle ID' >&2; exit 1; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GROUP="$TEAM.io.github.jwz-git.Daygo.widgets"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/daygo-widget-embed.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
"$ROOT/native/darwin/Widget/build.sh"
cp -R "$ROOT/build/native/darwin/widget/DaygoTimeline.appex" "$WORK/DaygoTimeline.appex"
EXT="$WORK/DaygoTimeline.appex"
# Preserve all existing host entitlements, including unrelated capabilities.
if ! codesign -d --entitlements - "$APP" > "$WORK/host.plist" 2>/dev/null; then
  rm -f "$WORK/host.plist"
fi
python3 - "$WORK" "$TEAM" "$GROUP" "$PLIST" <<'PY'
import sys,plistlib,os
work,team,group,host=sys.argv[1:]
path=work+'/host.plist'
if os.path.exists(path) and os.path.getsize(path):
    with open(path,'rb') as f: entitlements=plistlib.load(f)
else: entitlements={}
groups=entitlements.get('com.apple.security.application-groups',[])
if group not in groups: groups.append(group)
entitlements['com.apple.security.application-groups']=groups
with open(path,'wb') as f:plistlib.dump(entitlements,f)
with open(work+'/extension.plist','wb') as f:plistlib.dump({'com.apple.security.app-sandbox':True,'com.apple.security.application-groups':[group]},f)
with open(host,'rb') as f:metadata=plistlib.load(f)
ext=work+'/DaygoTimeline.appex/Contents/Info.plist'
with open(ext,'rb') as f:extension=plistlib.load(f)
extension['DaygoWidgetAppGroup']=group
for key in ['CFBundleVersion','CFBundleShortVersionString']:extension[key]=metadata[key]
with open(ext,'wb') as f:plistlib.dump(extension,f)
PY
codesign --force --options runtime --entitlements "$WORK/extension.plist" --sign "$IDENTITY" "$EXT"
ACTUAL_TEAM="$(codesign -dv --verbose=4 "$EXT" 2>&1 | sed -n 's/^TeamIdentifier=//p')"
[[ "$ACTUAL_TEAM" == "$TEAM" ]] || { echo 'Signing identity does not match team ID' >&2; exit 1; }
# Validate the signed extension before changing the development host.
codesign --verify --strict "$EXT"
mkdir -p "$APP/Contents/PlugIns"
[[ ! -e "$APP/Contents/PlugIns/DaygoTimeline.appex" ]] || { echo 'Extension already exists; use a fresh development app' >&2; exit 1; }
cp -R "$EXT" "$APP/Contents/PlugIns/"
/usr/libexec/PlistBuddy -c 'Delete :DaygoWidgetAppGroup' "$PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :DaygoWidgetAppGroup string $GROUP" "$PLIST"
codesign --force --options runtime --entitlements "$WORK/host.plist" --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict "$APP"
printf 'Development app ready: %s\nLaunch it once, then add Daygo from Edit Widgets.\n' "$APP"
