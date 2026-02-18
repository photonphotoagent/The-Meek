#!/bin/bash
# build.sh — Build and install the Modern Zoom Transition for Final Cut Pro.
#
# Usage:
#   ./build.sh          Build the plugin
#   ./build.sh install  Build + install to FxPlug plugins folder
#   ./build.sh clean    Clean build artifacts
#
# Requirements:
#   - macOS 14.0+
#   - Xcode 15+ with Metal & FxPlug frameworks
#   - Final Cut Pro 10.8+ (FCPX 12)

set -euo pipefail

PLUGIN_NAME="ModernZoomTransition"
BUNDLE_EXT="fxplug"
BUILD_DIR="build"
INSTALL_DIR="$HOME/Library/Plug-Ins/FxPlug"
SOURCES="Source/*.swift"
METAL_SOURCE="Metal/ZoomTransitionKernel.metal"
RESOURCES="Resources/Info.plist"
MIN_MACOS="14.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[BUILD]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

# Verify we're on macOS
[[ "$(uname)" == "Darwin" ]] || err "This plugin must be built on macOS."

# Verify Xcode
command -v xcrun &>/dev/null || err "Xcode command line tools not found. Install with: xcode-select --install"

clean() {
    log "Cleaning build artifacts..."
    rm -rf "$BUILD_DIR"
    log "Clean complete."
}

build() {
    log "Building $PLUGIN_NAME..."

    mkdir -p "$BUILD_DIR/$PLUGIN_NAME.$BUNDLE_EXT/Contents/MacOS"
    mkdir -p "$BUILD_DIR/$PLUGIN_NAME.$BUNDLE_EXT/Contents/Resources"

    # --- Compile Metal shader ---
    log "Compiling Metal shader..."
    xcrun -sdk macosx metal \
        -target air64-apple-macos${MIN_MACOS} \
        -c "$METAL_SOURCE" \
        -o "$BUILD_DIR/ZoomTransitionKernel.air"

    xcrun -sdk macosx metallib \
        "$BUILD_DIR/ZoomTransitionKernel.air" \
        -o "$BUILD_DIR/$PLUGIN_NAME.$BUNDLE_EXT/Contents/Resources/default.metallib"

    log "Metal shader compiled."

    # --- Compile Swift sources ---
    log "Compiling Swift sources..."
    xcrun -sdk macosx swiftc \
        -target arm64-apple-macos${MIN_MACOS} \
        -O \
        -module-name ZoomTransition \
        -emit-library \
        -o "$BUILD_DIR/$PLUGIN_NAME.$BUNDLE_EXT/Contents/MacOS/$PLUGIN_NAME" \
        -Xcc -fmodule-map-file=Modules/module.modulemap \
        -F /Library/Developer/SDKs/FxPlug.sdk/Library/Frameworks \
        -F /Library/Developer/Frameworks \
        -framework FxPlug \
        -framework Metal \
        -framework CoreMedia \
        -framework CoreVideo \
        -framework Foundation \
        $SOURCES

    log "Swift sources compiled."

    # --- Copy resources ---
    cp "$RESOURCES" "$BUILD_DIR/$PLUGIN_NAME.$BUNDLE_EXT/Contents/Info.plist"

    log "Build complete: $BUILD_DIR/$PLUGIN_NAME.$BUNDLE_EXT"
}

install() {
    build

    log "Installing to $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    rm -rf "$INSTALL_DIR/$PLUGIN_NAME.$BUNDLE_EXT"
    cp -R "$BUILD_DIR/$PLUGIN_NAME.$BUNDLE_EXT" "$INSTALL_DIR/"

    log "Installed! Restart Final Cut Pro to load the transition."
    log "The transition will appear under: Transitions → The Meek → Modern Zoom"
}

# --- Main ---
case "${1:-build}" in
    clean)   clean ;;
    build)   build ;;
    install) install ;;
    *)       echo "Usage: $0 {build|install|clean}"; exit 1 ;;
esac
