#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "=== Building OmniRoute for macOS ==="

# 1. Ensure resources exist
if [ ! -f "resources/AppIcon.icns" ]; then
    echo "Generating app icons..."
    python3 scripts/generate_icon.py
fi

# 2. Setup App Bundle structure
APP_NAME="OmniRoute.app"
CONTENTS="$APP_NAME/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Creating bundle structure: $APP_NAME"
rm -rf "$APP_NAME"
mkdir -p "$MACOS" "$RESOURCES"

# 3. Copy Bundle Metadata
cp resources/Info.plist "$CONTENTS/Info.plist"
echo -n "APPL????" > "$CONTENTS/PkgInfo"
cp resources/AppIcon.icns "$RESOURCES/AppIcon.icns"
cp resources/icon.png "$RESOURCES/icon.png"

# 4. Compile Swift sources
echo "Compiling Swift code with swiftc..."
CACHE_DIR="/tmp/clang-cache"
mkdir -p "$CACHE_DIR"

SDK_PATH=$(xcrun --show-sdk-path 2>/dev/null || echo "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk")

swiftc -module-cache-path "$CACHE_DIR" \
  -parse-as-library \
  -sdk "$SDK_PATH" \
  -target arm64-apple-macosx13.0 \
  -O \
  src/Models/ServerStatus.swift \
  src/Models/LogEntry.swift \
  src/Models/AppState.swift \
  src/Helpers/EnvironmentHelper.swift \
  src/Views/StatusCardView.swift \
  src/Views/ConsoleView.swift \
  src/Views/IntegrationsView.swift \
  src/Views/SettingsView.swift \
  src/Views/ContentView.swift \
  src/Main.swift \
  -o "$MACOS/OmniRoute"

chmod +x "$MACOS/OmniRoute"

# 5. Ad-hoc codesign bundle
echo "Ad-hoc code signing $APP_NAME..."
codesign --force --deep --sign - "$APP_NAME"

echo "=== Build Complete! ==="
echo "Application bundle created at: $DIR/$APP_NAME"
ls -ld "$APP_NAME"
