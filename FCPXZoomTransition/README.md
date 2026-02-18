# Modern Zoom Transition for Final Cut Pro

A GPU-accelerated zoom transition plugin for Final Cut Pro (10.8+ / FCPX 12), built with Apple's **FxPlug 4** framework and **Metal** shaders.

## Features

- **4 Zoom Styles** — Zoom In, Zoom Out, Zoom Through, Whip Zoom
- **6 Easing Curves** — Linear, Ease In/Out, Exponential, Elastic (with bounce)
- **GPU-accelerated** — Metal compute shader for real-time playback at 4K+
- **Radial Motion Blur** — Configurable sample count for smooth zoom blur
- **Chromatic Aberration** — Subtle RGB fringing for a cinematic look
- **Vignette** — Auto-animated darkening during the transition midpoint
- **Customizable Center Point** — Zoom into any part of the frame
- **Rotation** — Add spin during the zoom for dynamic energy

## Project Structure

```
FCPXZoomTransition/
├── Source/
│   ├── ZoomTransition.swift          # Main FxPlug transition logic
│   ├── ZoomTransitionFactory.swift   # Plugin discovery & registration
│   └── ZoomUniforms.swift            # Shared CPU/GPU uniform struct
├── Metal/
│   └── ZoomTransitionKernel.metal    # GPU compute shader
├── Resources/
│   └── Info.plist                    # Bundle configuration
├── FCPXML/
│   └── zoom-transition-template.fcpxml  # XML-based alternative (no build)
├── Package.swift                     # Swift Package Manager manifest
├── build.sh                          # Build & install script
└── README.md
```

## Requirements

- **macOS 14.0+** (Sonoma or later)
- **Xcode 15+** with Metal and FxPlug frameworks
- **Final Cut Pro 10.8+** (marketed as FCPX 12 / Final Cut Pro for Mac)

## Quick Start

### Option A: Xcode (recommended)

1. **Open the project**
   ```
   open FCPXZoomTransition.xcodeproj
   ```
2. **Build & install**: Press **Cmd+B**
   - Compiles Swift sources + Metal shader
   - A post-build script auto-copies the plugin to `~/Library/Plug-Ins/FxPlug/`
3. **Run with FCP**: Press **Cmd+R**
   - Builds, installs, and launches Final Cut Pro automatically
4. The transition appears under **Transitions → The Meek → Modern Zoom**

### Option B: Command line (no Xcode UI)

```bash
cd FCPXZoomTransition

# Build only
./build.sh

# Build and install to ~/Library/Plug-Ins/FxPlug/
./build.sh install

# Clean build artifacts
./build.sh clean
```

After installing, **restart Final Cut Pro**. The transition will appear under:

> **Transitions → The Meek → Modern Zoom**

### Option C: Import the FCPXML template (no build required)

If you don't want to compile anything, use the FCPXML template:

1. Open Final Cut Pro
2. **File → Import → XML...**
3. Select `FCPXML/zoom-transition-template.fcpxml`
4. Two template projects will appear: **Zoom Through** and **Whip Zoom**
5. Replace the placeholder gaps with your clips
6. Adjust keyframes in the **Video Inspector**

## Parameters

When using the FxPlug plugin, these parameters are exposed in the FCPX Inspector:

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| **Style** | Menu | Zoom Through | Zoom In, Out, Through, or Whip |
| **Zoom Amount** | 1.5–50× | 8× | Peak scale factor |
| **Center X/Y** | 0.0–1.0 | 0.5, 0.5 | Zoom focal point |
| **Rotation** | ±360° | 0° | Degrees of spin during zoom |
| **Easing** | Menu | Ease In/Out | Animation curve |
| **Bounce** | 0.0–1.0 | 0.3 | Elastic overshoot amount |
| **Motion Blur** | On/Off | On | Radial zoom blur |
| **Blur Samples** | 4–64 | 16 | Quality of motion blur |
| **Chromatic Aberration** | 0–20 px | 0 | RGB fringe offset |
| **Vignette** | 0.0–1.0 | 0.3 | Edge darkening strength |

## Zoom Styles Explained

### Zoom In
Clip A scales up from normal to the peak zoom, fading out. Clip B is revealed behind at normal scale.

### Zoom Out
Clip A shrinks toward zero. Clip B is revealed behind at normal scale.

### Zoom Through
The signature look — Clip A zooms in past the camera, then Clip B emerges by zooming out from the peak. Creates a "traveling through" effect.

### Whip Zoom
An aggressive, fast zoom with squared acceleration. Both clips zoom simultaneously with heavy motion blur for a frenetic editorial feel.

## Architecture

The plugin uses Apple's **FxPlug 4** API:

- `ZoomTransition` implements `FxTransition` — handles parameter setup, timing, and dispatches Metal rendering
- `ZoomTransitionFactory` implements `FxPluginFactory` — registers the plugin with FCP
- `ZoomTransitionKernel.metal` — a Metal compute shader that performs per-pixel zoom sampling, compositing, chromatic aberration, motion blur, and vignette in a single pass
- `ZoomUniforms` — shared struct ensuring CPU/GPU data layout matches exactly

## License

This project is part of **The Meek** repository.
