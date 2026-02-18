#!/bin/bash
# setup_fxplug_module.sh
# One-time setup: installs module.modulemap into FxPlug.framework
# so that Swift can use `import FxPlug`.
#
# The FxPlug SDK ships without a modulemap, which prevents Swift imports.
# This script adds one inside the framework where Xcode expects it.
#
# Usage:  ./setup_fxplug_module.sh
# Requires: sudo (writes to /Library/Developer)

set -euo pipefail

FXPLUG_FW="/Library/Developer/SDKs/FxPlug.sdk/Library/Frameworks/FxPlug.framework"
MODULES_DIR="$FXPLUG_FW/Versions/A/Modules"
MODULEMAP="$MODULES_DIR/module.modulemap"

# Check if already installed
if [ -f "$MODULEMAP" ]; then
    echo "✓ FxPlug module.modulemap is already installed."
    exit 0
fi

# Check FxPlug SDK is present
if [ ! -d "$FXPLUG_FW" ]; then
    echo "ERROR: FxPlug.framework not found at:"
    echo "  $FXPLUG_FW"
    echo ""
    echo "Install the FxPlug SDK from:"
    echo "  https://developer.apple.com/download/all/?q=FxPlug"
    exit 1
fi

echo "Installing module.modulemap into FxPlug.framework..."
echo "(This requires sudo to write to /Library/Developer)"
echo ""

sudo mkdir -p "$MODULES_DIR"

sudo tee "$MODULEMAP" > /dev/null << 'MODULEMAP_EOF'
framework module FxPlug [system] {
    umbrella header "FxPlugSDK.h"
    link framework "FxPlug"
    export *
    module * { export * }
}
MODULEMAP_EOF

# Add Modules symlink in Versions/Current if needed
if [ -d "$FXPLUG_FW/Versions/Current" ] && [ ! -e "$FXPLUG_FW/Versions/Current/Modules" ]; then
    sudo ln -s ../A/Modules "$FXPLUG_FW/Versions/Current/Modules"
fi

# Add top-level Modules symlink if needed
if [ ! -e "$FXPLUG_FW/Modules" ]; then
    sudo ln -s Versions/Current/Modules "$FXPLUG_FW/Modules"
fi

echo ""
echo "✓ Done! FxPlug.framework now supports 'import FxPlug' in Swift."
echo "  You can now build the project in Xcode (Cmd+B)."
