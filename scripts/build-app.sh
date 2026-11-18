#!/bin/bash
# Builds build/Spacer.app from the release binary.
#   --install    also replaces /Applications/Spacer.app
#   --universal  builds for both Apple silicon and Intel
set -euo pipefail
cd "$(dirname "$0")/.."

BUNDLE_ID=com.freberdev.spacer
INSTALLED=/Applications/Spacer.app

INSTALL=0
ARCH_FLAGS=()
for arg in "$@"; do
    case "$arg" in
        --install) INSTALL=1 ;;
        --universal) ARCH_FLAGS=(--arch arm64 --arch x86_64) ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

bundle_id() { # bundle_id <app>
    /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$1/Contents/Info.plist" 2>/dev/null || true
}

# Never replace somebody else's app that happens to share the name.
if [ "$INSTALL" = 1 ] && [ -e "$INSTALLED" ] && [ "$(bundle_id "$INSTALLED")" != "$BUNDLE_ID" ]; then
    echo "$INSTALLED is a different app ($(bundle_id "$INSTALLED")). Move it away first." >&2
    exit 1
fi

swift build -c release ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"}
BIN="$(swift build -c release ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"} --show-bin-path)/SpacerApp"

APP=build/Spacer.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Spacer"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi
for lproj in Resources/*.lproj; do
    [ -d "$lproj" ] && cp -R "$lproj" "$APP/Contents/Resources/"
done

# Signing identity: $SPACER_SIGN_IDENTITY, else the first line of .signing-identity, else ad hoc.
# A real certificate keeps the login item across rebuilds.
IDENTITY="${SPACER_SIGN_IDENTITY:-}"
if [ -z "$IDENTITY" ] && [ -f .signing-identity ]; then
    IDENTITY="$(sed -n '1{s/^[[:space:]]*//;s/[[:space:]]*$//;p;}' .signing-identity)"
fi
if [ -z "$IDENTITY" ] || [ "$IDENTITY" = "-" ]; then
    codesign --force --sign - "$APP"
    echo "Built $APP (signed ad hoc)"
else
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
    echo "Built $APP (signed with a certificate)"
fi

if [ "$INSTALL" = 1 ]; then
    # Only ask a running app to quit; "tell application" would otherwise launch it.
    running() { pgrep -f "^$INSTALLED/Contents/MacOS/Spacer" >/dev/null; }
    if running; then
        osascript -e "tell application id \"$BUNDLE_ID\" to quit" 2>/dev/null || true
    fi
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        running || break
        sleep 0.5
    done
    pkill -f "^$INSTALLED/Contents/MacOS/Spacer" 2>/dev/null || true
    rm -rf "$INSTALLED"
    cp -R "$APP" "$INSTALLED"
    echo "Installed $INSTALLED"
fi
