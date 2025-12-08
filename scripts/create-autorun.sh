#!/bin/bash

# This script creates an AppleScript application that auto-launches
# when the thumb drive is plugged in

set -e

# Get the parent directory (deep_seek_llama root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$SCRIPT_DIR"

echo "════════════════════════════════════════════════════════"
echo "  Creating Auto-Launch Application"
echo "════════════════════════════════════════════════════════"
echo ""

# Create the AppleScript application at ROOT level (not in scripts/)
APP_PATH="$SCRIPT_DIR/🚀 Start DeepSeek.app"

echo "Creating application bundle..."

# Create the app bundle structure
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Create Info.plist
cat > "$APP_PATH/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.deepseek.v3.launcher</string>
    <key>CFBundleName</key>
    <string>Start DeepSeek</string>
    <key>CFBundleDisplayName</key>
    <string>🚀 Start DeepSeek</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
PLIST

# Create the executable script that calls launcher.sh
cat > "$APP_PATH/Contents/MacOS/launcher" << 'EXEC'
#!/bin/bash

# Get the directory where this app is located (thumb drive root)
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../.. && pwd )"
cd "$APP_DIR"

# Run the GUI launcher
./scripts/launcher.sh
EXEC

chmod +x "$APP_PATH/Contents/MacOS/launcher"

# Create a simple text-based icon placeholder
cat > "$APP_PATH/Contents/Resources/AppIcon.icns" << 'ICON'
This is a placeholder. For a real icon, replace this with an actual .icns file.
To create one: Use Image2Icon or similar tool to convert a PNG to ICNS format.
ICON

echo "✅ Created: $APP_PATH"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 USAGE INSTRUCTIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ The app has been created at the ROOT of your drive!"
echo ""
echo "Users can now simply:"
echo "  1. Plug in the thumb drive"
echo "  2. Open the thumb drive in Finder"
echo "  3. Double-click: '🚀 Start DeepSeek.app'"
echo "  4. Done! Everything else is automatic."
echo ""
echo "⚠️  FIRST RUN SECURITY:"
echo "   macOS will show a security warning the first time."
echo "   Tell users to:"
echo "     • Right-click (Control+click) the app"
echo "     • Select 'Open'"
echo "     • Click 'Open' in the dialog"
echo "     • This only needs to be done ONCE per Mac"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
