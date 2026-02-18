// ZoomTransitionKernel.metal
// GPU compute shader for the Modern Zoom transition.
//
// This kernel composites two source images (A → outgoing, B → incoming)
// with per-pixel zoom, rotation, radial motion blur, chromatic aberration,
// and vignette effects — all running on the GPU for real-time playback.

#include <metal_stdlib>
using namespace metal;

// Must match ZoomUniforms.swift layout exactly
struct ZoomUniforms {
    float scaleA;
    float scaleB;
    float opacityA;
    float opacityB;
    float rotationA;
    float rotationB;
    float centerX;
    float centerY;
    float progress;
    int   motionBlurEnabled;
    int   blurSamples;
    float chromaticAberration;
    float vignetteAmount;
    float maxZoom;
};

// MARK: - Utility Functions

/// Rotate a 2D point around origin by angle (radians).
static float2 rotate2D(float2 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float2(
        point.x * c - point.y * s,
        point.x * s + point.y * c
    );
}

/// Sample a texture at normalized UV coordinates with clamp-to-edge behavior.
static float4 sampleClamped(texture2d<float, access::read> tex,
                             float2 uv,
                             uint2 dims) {
    // Clamp UV to valid range
    float2 clampedUV = clamp(uv, float2(0.0), float2(1.0));
    uint2 coord = uint2(clampedUV * float2(dims));
    coord = min(coord, dims - uint2(1));
    return tex.read(coord);
}

/// Sample with chromatic aberration (shifts R and B channels radially).
static float4 sampleChromatic(texture2d<float, access::read> tex,
                               float2 uv,
                               float2 center,
                               float aberration,
                               uint2 dims) {
    if (aberration < 0.001) {
        return sampleClamped(tex, uv, dims);
    }

    float2 dir = uv - center;
    float dist = length(dir);
    float2 offset = normalize(dir + float2(0.0001)) * aberration / float2(dims);

    float r = sampleClamped(tex, uv + offset * dist, dims).r;
    float g = sampleClamped(tex, uv, dims).g;
    float b = sampleClamped(tex, uv - offset * dist, dims).b;
    float a = sampleClamped(tex, uv, dims).a;

    return float4(r, g, b, a);
}

/// Compute a transformed UV for a given zoom scale, rotation, and center.
static float2 transformUV(float2 uv, float2 center, float scale, float rotation) {
    // Translate so center is at origin
    float2 p = uv - center;

    // Apply inverse rotation
    p = rotate2D(p, -rotation);

    // Apply inverse scale
    p /= scale;

    // Translate back
    return p + center;
}

/// Compute vignette darkening factor.
static float vignetteFor(float2 uv, float amount) {
    if (amount < 0.001) return 1.0;
    float2 centered = uv - float2(0.5);
    float dist = length(centered) * 2.0;  // 0 at center, ~1.414 at corners
    float vig = 1.0 - smoothstep(0.5, 1.5, dist) * amount;
    return vig;
}

// MARK: - Radial Motion Blur

/// Sample a source with radial (zoom) motion blur emanating from center.
static float4 sampleWithMotionBlur(texture2d<float, access::read> tex,
                                    float2 uv,
                                    float2 center,
                                    float scale,
                                    float rotation,
                                    float chromatic,
                                    int samples,
                                    uint2 dims) {
    if (samples <= 1) {
        float2 transformedUV = transformUV(uv, center, scale, rotation);
        return sampleChromatic(tex, transformedUV, center, chromatic, dims);
    }

    float4 accum = float4(0.0);
    float totalWeight = 0.0;

    // Spread samples across a small range of the current scale
    float blurRange = max(0.02, (scale - 1.0) * 0.05);

    for (int i = 0; i < samples; i++) {
        float t = float(i) / float(samples - 1);  // 0..1
        float sampleScale = scale * (1.0 - blurRange + blurRange * 2.0 * t);
        float sampleRotation = rotation * (1.0 - blurRange + blurRange * 2.0 * t);

        float2 sampleUV = transformUV(uv, center, sampleScale, sampleRotation);

        // Gaussian-ish weight: higher at center of sample range
        float weight = 1.0 - abs(t - 0.5) * 2.0;
        weight = weight * weight;
        weight = max(weight, 0.1);

        float4 s = sampleChromatic(tex, sampleUV, center, chromatic, dims);
        accum += s * weight;
        totalWeight += weight;
    }

    return accum / totalWeight;
}

// MARK: - Main Kernel

kernel void zoomTransitionKernel(
    texture2d<float, access::read>  sourceA    [[texture(0)]],
    texture2d<float, access::read>  sourceB    [[texture(1)]],
    texture2d<float, access::write> destination [[texture(2)]],
    constant ZoomUniforms&          uniforms   [[buffer(0)]],
    uint2                           gid        [[thread_position_in_grid]])
{
    uint2 destSize = uint2(destination.get_width(), destination.get_height());

    // Bounds check
    if (gid.x >= destSize.x || gid.y >= destSize.y) return;

    // Normalized UV coordinates
    float2 uv = float2(gid) / float2(destSize);
    float2 center = float2(uniforms.centerX, uniforms.centerY);

    uint2 sizeA = uint2(sourceA.get_width(), sourceA.get_height());
    uint2 sizeB = uint2(sourceB.get_width(), sourceB.get_height());

    // --- Sample source A (outgoing clip) ---
    float4 colorA;
    if (uniforms.motionBlurEnabled != 0 && uniforms.scaleA > 1.05) {
        colorA = sampleWithMotionBlur(
            sourceA, uv, center,
            uniforms.scaleA, uniforms.rotationA,
            uniforms.chromaticAberration,
            uniforms.blurSamples, sizeA
        );
    } else {
        float2 uvA = transformUV(uv, center, uniforms.scaleA, uniforms.rotationA);
        colorA = sampleChromatic(sourceA, uvA, center,
                                  uniforms.chromaticAberration, sizeA);
    }

    // --- Sample source B (incoming clip) ---
    float4 colorB;
    if (uniforms.motionBlurEnabled != 0 && uniforms.scaleB > 1.05) {
        colorB = sampleWithMotionBlur(
            sourceB, uv, center,
            uniforms.scaleB, uniforms.rotationB,
            uniforms.chromaticAberration,
            uniforms.blurSamples, sizeB
        );
    } else {
        float2 uvB = transformUV(uv, center, uniforms.scaleB, uniforms.rotationB);
        colorB = sampleChromatic(sourceB, uvB, center,
                                  uniforms.chromaticAberration, sizeB);
    }

    // --- Composite ---
    // Apply per-source opacity
    colorA.a *= uniforms.opacityA;
    colorB.a *= uniforms.opacityB;

    // Premultiplied alpha composite: B over A
    // (B is incoming, drawn on top; A is outgoing, behind)
    float4 result;
    result.rgb = colorB.rgb * colorB.a + colorA.rgb * colorA.a * (1.0 - colorB.a);
    result.a   = colorB.a + colorA.a * (1.0 - colorB.a);

    // Unpremultiply for final output if alpha > 0
    if (result.a > 0.001) {
        result.rgb /= result.a;
    }

    // --- Vignette ---
    float vig = vignetteFor(uv, uniforms.vignetteAmount * uniforms.progress * 4.0
                            * (1.0 - uniforms.progress));
    result.rgb *= vig;

    // Clamp final color
    result = clamp(result, float4(0.0), float4(1.0));

    destination.write(result, gid);
}
