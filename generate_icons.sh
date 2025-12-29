#!/bin/bash
# Generate all macOS app icon sizes and in-app logos

APP_ICON="ccstatsapiconimg.png"
IN_APP_LOGO="ccstatsinsideicon.png"
ASSETS="Claude Usage/Assets.xcassets"

# Check if sources exist
if [ ! -f "$APP_ICON" ]; then
    echo "Error: $APP_ICON not found"
    exit 1
fi

if [ ! -f "$IN_APP_LOGO" ]; then
    echo "Error: $IN_APP_LOGO not found"
    exit 1
fi

# Generate App Icon sizes
echo "🎨 Generating App Icon sizes from $APP_ICON..."
DEST="$ASSETS/AppIcon.appiconset"

sips -z 16 16 "$APP_ICON" --out "$DEST/icon_16x16.png"
sips -z 32 32 "$APP_ICON" --out "$DEST/icon_16x16@2x.png"
sips -z 32 32 "$APP_ICON" --out "$DEST/icon_32x32.png"
sips -z 64 64 "$APP_ICON" --out "$DEST/icon_32x32@2x.png"
sips -z 128 128 "$APP_ICON" --out "$DEST/icon_128x128.png"
sips -z 256 256 "$APP_ICON" --out "$DEST/icon_128x128@2x.png"
sips -z 256 256 "$APP_ICON" --out "$DEST/icon_256x256.png"
sips -z 512 512 "$APP_ICON" --out "$DEST/icon_256x256@2x.png"
sips -z 512 512 "$APP_ICON" --out "$DEST/icon_512x512.png"
sips -z 1024 1024 "$APP_ICON" --out "$DEST/icon_512x512@2x.png"

echo "✅ App Icon done!"

# Generate In-App Logo sizes
echo ""
echo "🖼️ Generating In-App Logo sizes from $IN_APP_LOGO..."

# HeaderLogo (used in popover header)
sips -z 40 40 "$IN_APP_LOGO" --out "$ASSETS/HeaderLogo.imageset/header_logo_1x.png"
sips -z 80 80 "$IN_APP_LOGO" --out "$ASSETS/HeaderLogo.imageset/header_logo.png"

# WizardLogo (used in setup wizard)
sips -z 80 80 "$IN_APP_LOGO" --out "$ASSETS/WizardLogo.imageset/wizard_logo_1x.png"
sips -z 160 160 "$IN_APP_LOGO" --out "$ASSETS/WizardLogo.imageset/wizard_logo.png"

# AboutLogo (used in about view)
sips -z 64 64 "$IN_APP_LOGO" --out "$ASSETS/AboutLogo.imageset/about_logo_1x.png"
sips -z 128 128 "$IN_APP_LOGO" --out "$ASSETS/AboutLogo.imageset/about_logo.png"

echo "✅ In-App Logos done!"

echo ""
echo "🎉 All icons generated! Now rebuild in Xcode:"
echo "   1. Cmd+Shift+K (Clean Build)"
echo "   2. Cmd+B (Build)"
