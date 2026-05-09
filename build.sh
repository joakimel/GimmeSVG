#!/bin/bash
# Bygger Gimme SVG.app fra kildekoden i denne mappa.
# Bruk:  ./build.sh                              (skriver til ~/Desktop/Gimme SVG.app)
#        ./build.sh /path/to/output.app          (annen plassering)
#
# Ingen avhengigheter utover Xcode CLI tools (swiftc, codesign, sips, iconutil).

set -e
cd "$(dirname "$0")"

DEST_APP="${1:-$HOME/Desktop/Gimme SVG.app}"
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "→ Bygger Gimme SVG til $DEST_APP"

# 1. Kompiler hovedappen
echo "  • Kompilerer Swift-kildekoden …"
swiftc -O Sources/main.swift -o "$BUILD_DIR/GimmeSVG" \
  -framework Cocoa -framework SwiftUI -framework WebKit

# 2. Bygg .app-mappestruktur
rm -rf "$DEST_APP"
mkdir -p "$DEST_APP/Contents/MacOS"
mkdir -p "$DEST_APP/Contents/Resources"
cp "$BUILD_DIR/GimmeSVG" "$DEST_APP/Contents/MacOS/GimmeSVG"
chmod +x "$DEST_APP/Contents/MacOS/GimmeSVG"

# 3. Info.plist
cat > "$DEST_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>           <string>Gimme SVG</string>
    <key>CFBundleDisplayName</key>    <string>Gimme SVG</string>
    <key>CFBundleIdentifier</key>     <string>no.elden.gimmesvg</string>
    <key>CFBundleVersion</key>        <string>5</string>
    <key>CFBundleShortVersionString</key><string>1.3.0</string>
    <key>CFBundlePackageType</key>    <string>APPL</string>
    <key>CFBundleExecutable</key>     <string>GimmeSVG</string>
    <key>CFBundleIconFile</key>       <string>AppIcon</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSMinimumSystemVersion</key> <string>11.0</string>
    <key>NSPrincipalClass</key>       <string>NSApplication</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key><true/>
    </dict>
</dict>
</plist>
PLIST

# 4. Kopier hvit logo som ressurs (whitened v3-utgave for lilla header)
cp Resources/gs_full_logo_v3_white.svg "$DEST_APP/Contents/Resources/logo.svg"

# 5. Bygg AppIcon.icns fra Resources/app-icon.png
echo "  • Bygger AppIcon.icns …"
ICONSET="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
sips -z 1024 1024 Resources/gs_appicon_v3.png --out "$ICONSET/_master.png" >/dev/null

for spec in "16:icon_16x16.png"      "32:icon_16x16@2x.png" \
            "32:icon_32x32.png"      "64:icon_32x32@2x.png" \
            "128:icon_128x128.png"   "256:icon_128x128@2x.png" \
            "256:icon_256x256.png"   "512:icon_256x256@2x.png" \
            "512:icon_512x512.png"   "1024:icon_512x512@2x.png"; do
  size="${spec%%:*}"
  name="${spec##*:}"
  sips -z $size $size "$ICONSET/_master.png" --out "$ICONSET/$name" >/dev/null
done
rm "$ICONSET/_master.png"
iconutil -c icns "$ICONSET" -o "$DEST_APP/Contents/Resources/AppIcon.icns"

# 6. Ad-hoc signer
echo "  • Ad-hoc signerer appen …"
codesign --force --deep --sign - "$DEST_APP"

echo "✓ Ferdig: $DEST_APP"
echo ""
echo "Første gang du åpner appen: høyreklikk på den → Åpne"
echo "(macOS Gatekeeper viser advarsel for ad-hoc signerte apper)"
