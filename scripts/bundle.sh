#!/bin/bash
# Builds Klick.app bundle, codesigns, notarizes, and creates a DMG
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Klick"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
IDENTIFIER="com.cirx.klick"
VERSION="1.0.0"

# -- Configuration --
# Set these to your Apple Developer identity and credentials
# Find your identity with: security find-identity -v -p codesigning
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
TEAM_ID="${TEAM_ID:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-klick-notary}"

echo "=== Building $APP_NAME v$VERSION ==="

# Step 1: Build release binary
echo "[1/6] Building release binary..."
cd "$PROJECT_DIR"
swift build -c release 2>&1
BINARY="$PROJECT_DIR/.build/release/$APP_NAME"

if [ ! -f "$BINARY" ]; then
    echo "Error: Build failed, binary not found at $BINARY"
    exit 1
fi
echo "  Binary: $BINARY"

# Step 2: Create .app bundle
echo "[2/6] Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy sound resource from SPM build
SOUND_SOURCE="$PROJECT_DIR/.build/release/Klick_Klick.bundle/sound.caf"
if [ ! -f "$SOUND_SOURCE" ]; then
    SOUND_SOURCE="$PROJECT_DIR/Sources/Klick/Resources/sound.caf"
fi
cp "$SOUND_SOURCE" "$APP_BUNDLE/Contents/Resources/sound.caf"

# Copy SPM resource bundle if it exists
SPM_BUNDLE="$PROJECT_DIR/.build/release/Klick_Klick.bundle"
if [ -d "$SPM_BUNDLE" ]; then
    cp -R "$SPM_BUNDLE" "$APP_BUNDLE/Contents/Resources/"
fi

# Copy icon if it exists
if [ -f "$BUILD_DIR/AppIcon.icns" ]; then
    cp "$BUILD_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "  Warning: No AppIcon.icns found. Run scripts/create-icon.sh first."
fi

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "  Bundle: $APP_BUNDLE"

# Step 3: Codesign
if [ -n "$SIGN_IDENTITY" ]; then
    echo "[3/6] Codesigning..."
    codesign --force --deep --options runtime \
        --entitlements "$PROJECT_DIR/Klick.entitlements" \
        --sign "$SIGN_IDENTITY" \
        "$APP_BUNDLE"
    echo "  Signed with: $SIGN_IDENTITY"

    # Verify
    codesign --verify --deep --strict "$APP_BUNDLE"
    echo "  Signature verified"
else
    echo "[3/6] Skipping codesign (set SIGN_IDENTITY env var)"
    echo "  Find your identity with: security find-identity -v -p codesigning"
fi

# Step 4: Create DMG
echo "[4/6] Creating DMG..."
rm -f "$DMG_PATH"

# Create a temporary directory for DMG contents
DMG_STAGING="$BUILD_DIR/dmg-staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"

# Create symlink to Applications
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH" >/dev/null 2>&1

rm -rf "$DMG_STAGING"
echo "  DMG: $DMG_PATH"

# Step 5: Sign DMG
if [ -n "$SIGN_IDENTITY" ]; then
    echo "[5/6] Signing DMG..."
    codesign --force --sign "$SIGN_IDENTITY" "$DMG_PATH"
    echo "  DMG signed"
else
    echo "[5/6] Skipping DMG signing"
fi

# Step 6: Notarize
if [ -n "$SIGN_IDENTITY" ]; then
    echo "[6/6] Notarizing..."
    echo "  Submitting to Apple..."
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait

    echo "  Stapling notarization ticket..."
    xcrun stapler staple "$DMG_PATH"
    echo "  Notarization complete"
else
    echo "[6/6] Skipping notarization"
fi

echo ""
echo "=== Done ==="
echo "App:  $APP_BUNDLE"
echo "DMG:  $DMG_PATH"
echo ""
if [ -z "$SIGN_IDENTITY" ]; then
    echo "To sign and notarize, run:"
    echo "  1. security find-identity -v -p codesigning"
    echo "  2. xcrun notarytool store-credentials klick-notary"
    echo "  3. SIGN_IDENTITY=\"Developer ID Application: Your Name (TEAMID)\" TEAM_ID=\"TEAMID\" ./scripts/bundle.sh"
fi
