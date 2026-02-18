// ZoomUniforms.swift
// Shared uniform structure between Swift and Metal shader.

import simd

/// Uniforms passed to the Metal compute kernel.
/// Must match the layout in ZoomTransitionKernel.metal exactly.
struct ZoomUniforms {
    var scaleA: Float
    var scaleB: Float
    var opacityA: Float
    var opacityB: Float
    var rotationA: Float           // radians
    var rotationB: Float           // radians
    var centerX: Float             // 0.0 - 1.0 normalized
    var centerY: Float             // 0.0 - 1.0 normalized
    var progress: Float            // 0.0 - 1.0 transition progress
    var motionBlurEnabled: Int32   // 0 or 1
    var blurSamples: Int32         // 4 - 64
    var chromaticAberration: Float // 0.0 - 20.0 pixel offset
    var vignetteAmount: Float      // 0.0 - 1.0
    var maxZoom: Float             // max scale factor
}
