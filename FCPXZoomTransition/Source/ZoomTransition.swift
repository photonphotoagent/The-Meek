// ZoomTransition.swift
// Modern Zoom Transition for Final Cut Pro
//
// A GPU-accelerated zoom transition plugin using Apple's FxPlug 4 framework.
// Supports zoom-in, zoom-out, zoom-through, and whip-zoom styles with
// customizable easing, motion blur, center point, and rotation.

import Foundation
import FxPlug

// MARK: - Parameter IDs

enum ParameterID: UInt32 {
    case zoomStyle       = 1
    case zoomScale       = 2
    case centerX         = 3
    case centerY         = 4
    case rotation        = 5
    case motionBlur      = 6
    case blurSamples     = 7
    case easingCurve     = 8
    case bounceFactor    = 9
    case chromatic       = 10
    case vignetteAmount  = 11
}

// MARK: - Zoom Styles

enum ZoomStyle: Int {
    case zoomIn       = 0  // A zooms in, B appears behind
    case zoomOut      = 1  // A shrinks out, B revealed
    case zoomThrough  = 2  // Zoom into A, emerge from B
    case whipZoom     = 3  // Fast directional zoom with motion blur
}

// MARK: - Easing Curves

enum EasingCurve: Int {
    case linear       = 0
    case easeIn       = 1
    case easeOut      = 2
    case easeInOut    = 3
    case exponential  = 4
    case elastic      = 5
}

// MARK: - ZoomTransition Plugin

@objc class ZoomTransition: NSObject, FxTransition {

    // MARK: - Properties

    private var apiManager: PROAPIAccessing?

    // MARK: - FxTransition Protocol

    required init?(apiManager: PROAPIAccessing) {
        self.apiManager = apiManager
        super.init()
    }

    // MARK: - Plugin Properties

    func pluginInstanceAddedToDocument() {
        // Called when the transition is added to the timeline
    }

    var properties: [String: Any] {
        return [
            kFxPropertyKey_MayRemapTime: false,
            kFxPropertyKey_PixelIndependent: false,
            kFxPropertyKey_PreservesAlpha: true,
            kFxPropertyKey_PixelTransformSupport: kFxPixelTransform_ScaleTranslate,
            kFxPropertyKey_ChangesOutputSize: false,
        ]
    }

    // MARK: - Parameter Setup

    func addParameters() throws {
        guard let paramAPI = apiManager?.api(for: FxParameterCreationAPI_v5.self)
                as? FxParameterCreationAPI_v5 else {
            throw NSError(domain: "ZoomTransition", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to get parameter creation API"])
        }

        // --- Group: Zoom ---
        try paramAPI.startParameterSubGroup("Zoom",
                                            parameterID: 100,
                                            parameterFlags: .defaultFlags)

        // Zoom Style popup
        let styleEntries: [FxPopupEntry] = [
            FxPopupEntry(title: "Zoom In", value: ZoomStyle.zoomIn.rawValue),
            FxPopupEntry(title: "Zoom Out", value: ZoomStyle.zoomOut.rawValue),
            FxPopupEntry(title: "Zoom Through", value: ZoomStyle.zoomThrough.rawValue),
            FxPopupEntry(title: "Whip Zoom", value: ZoomStyle.whipZoom.rawValue),
        ]
        try paramAPI.addPopupMenu(withName: "Style",
                                  parameterID: ParameterID.zoomStyle.rawValue,
                                  defaultValue: ZoomStyle.zoomThrough.rawValue,
                                  menuEntries: styleEntries,
                                  parameterFlags: .defaultFlags)

        // Zoom Scale (how far to zoom, 1.0 = 100% to max)
        try paramAPI.addFloatSlider(withName: "Zoom Amount",
                                    parameterID: ParameterID.zoomScale.rawValue,
                                    defaultValue: 8.0,
                                    parameterMin: 1.5,
                                    parameterMax: 50.0,
                                    sliderMin: 1.5,
                                    sliderMax: 20.0,
                                    delta: 0.1,
                                    parameterFlags: .defaultFlags)

        // Center X
        try paramAPI.addFloatSlider(withName: "Center X",
                                    parameterID: ParameterID.centerX.rawValue,
                                    defaultValue: 0.5,
                                    parameterMin: 0.0,
                                    parameterMax: 1.0,
                                    sliderMin: 0.0,
                                    sliderMax: 1.0,
                                    delta: 0.01,
                                    parameterFlags: .defaultFlags)

        // Center Y
        try paramAPI.addFloatSlider(withName: "Center Y",
                                    parameterID: ParameterID.centerY.rawValue,
                                    defaultValue: 0.5,
                                    parameterMin: 0.0,
                                    parameterMax: 1.0,
                                    sliderMin: 0.0,
                                    sliderMax: 1.0,
                                    delta: 0.01,
                                    parameterFlags: .defaultFlags)

        // Rotation (degrees added during zoom)
        try paramAPI.addFloatSlider(withName: "Rotation",
                                    parameterID: ParameterID.rotation.rawValue,
                                    defaultValue: 0.0,
                                    parameterMin: -360.0,
                                    parameterMax: 360.0,
                                    sliderMin: -90.0,
                                    sliderMax: 90.0,
                                    delta: 1.0,
                                    parameterFlags: .defaultFlags)

        try paramAPI.endParameterSubGroup()

        // --- Group: Motion ---
        try paramAPI.startParameterSubGroup("Motion",
                                            parameterID: 200,
                                            parameterFlags: .defaultFlags)

        // Easing Curve
        let easingEntries: [FxPopupEntry] = [
            FxPopupEntry(title: "Linear", value: EasingCurve.linear.rawValue),
            FxPopupEntry(title: "Ease In", value: EasingCurve.easeIn.rawValue),
            FxPopupEntry(title: "Ease Out", value: EasingCurve.easeOut.rawValue),
            FxPopupEntry(title: "Ease In/Out", value: EasingCurve.easeInOut.rawValue),
            FxPopupEntry(title: "Exponential", value: EasingCurve.exponential.rawValue),
            FxPopupEntry(title: "Elastic", value: EasingCurve.elastic.rawValue),
        ]
        try paramAPI.addPopupMenu(withName: "Easing",
                                  parameterID: ParameterID.easingCurve.rawValue,
                                  defaultValue: EasingCurve.easeInOut.rawValue,
                                  menuEntries: easingEntries,
                                  parameterFlags: .defaultFlags)

        // Bounce Factor (for elastic easing)
        try paramAPI.addFloatSlider(withName: "Bounce",
                                    parameterID: ParameterID.bounceFactor.rawValue,
                                    defaultValue: 0.3,
                                    parameterMin: 0.0,
                                    parameterMax: 1.0,
                                    sliderMin: 0.0,
                                    sliderMax: 1.0,
                                    delta: 0.01,
                                    parameterFlags: .defaultFlags)

        try paramAPI.endParameterSubGroup()

        // --- Group: Effects ---
        try paramAPI.startParameterSubGroup("Effects",
                                            parameterID: 300,
                                            parameterFlags: .defaultFlags)

        // Motion Blur toggle
        try paramAPI.addToggleButton(withName: "Motion Blur",
                                     parameterID: ParameterID.motionBlur.rawValue,
                                     defaultValue: true,
                                     parameterFlags: .defaultFlags)

        // Motion Blur Samples
        try paramAPI.addIntSlider(withName: "Blur Samples",
                                  parameterID: ParameterID.blurSamples.rawValue,
                                  defaultValue: 16,
                                  parameterMin: 4,
                                  parameterMax: 64,
                                  sliderMin: 4,
                                  sliderMax: 32,
                                  delta: 1,
                                  parameterFlags: .defaultFlags)

        // Chromatic Aberration
        try paramAPI.addFloatSlider(withName: "Chromatic Aberration",
                                    parameterID: ParameterID.chromatic.rawValue,
                                    defaultValue: 0.0,
                                    parameterMin: 0.0,
                                    parameterMax: 20.0,
                                    sliderMin: 0.0,
                                    sliderMax: 10.0,
                                    delta: 0.1,
                                    parameterFlags: .defaultFlags)

        // Vignette
        try paramAPI.addFloatSlider(withName: "Vignette",
                                    parameterID: ParameterID.vignetteAmount.rawValue,
                                    defaultValue: 0.3,
                                    parameterMin: 0.0,
                                    parameterMax: 1.0,
                                    sliderMin: 0.0,
                                    sliderMax: 1.0,
                                    delta: 0.01,
                                    parameterFlags: .defaultFlags)

        try paramAPI.endParameterSubGroup()
    }

    // MARK: - Parameter Retrieval

    func parameterChanged(_ parameterID: UInt32, at time: CMTime) {
        // React to parameter changes if needed
    }

    // MARK: - Rendering

    func destinationImageRect(_ destinationImage: FxImageTile,
                              sourceImages: [FxImageTile],
                              destinationPluginState pluginState: Data?,
                              at renderTime: CMTime) -> CGRect {
        return destinationImage.imagePixelBounds
    }

    func sourceTileRect(_ sourceImage: FxImageTile,
                        sourceImageIndex: UInt,
                        sourceImages: [FxImageTile],
                        destinationTileRect: CGRect,
                        destinationPluginState pluginState: Data?,
                        at renderTime: CMTime) -> CGRect {
        return sourceImage.imagePixelBounds
    }

    func renderDestinationImage(_ destinationImage: FxImageTile,
                                sourceImages: [FxImageTile],
                                pluginState: Data?,
                                at renderTime: CMTime) throws {
        guard sourceImages.count >= 2 else {
            throw NSError(domain: "ZoomTransition", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Transition requires two source images"])
        }

        guard let paramAPI = apiManager?.api(for: FxParameterRetrievalAPI_v6.self)
                as? FxParameterRetrievalAPI_v6 else {
            throw NSError(domain: "ZoomTransition", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to get parameter retrieval API"])
        }

        guard let timingAPI = apiManager?.api(for: FxTimingAPI_v4.self)
                as? FxTimingAPI_v4 else {
            throw NSError(domain: "ZoomTransition", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to get timing API"])
        }

        // Get transition progress (0.0 to 1.0)
        let progress = try timingAPI.transitionProgress(at: renderTime)

        // Retrieve parameters
        var styleValue: Int = 0
        try paramAPI.getIntValue(&styleValue,
                                 fromParameter: ParameterID.zoomStyle.rawValue,
                                 at: renderTime)
        let style = ZoomStyle(rawValue: styleValue) ?? .zoomThrough

        var zoomScale: Double = 8.0
        try paramAPI.getFloatValue(&zoomScale,
                                   fromParameter: ParameterID.zoomScale.rawValue,
                                   at: renderTime)

        var centerX: Double = 0.5
        try paramAPI.getFloatValue(&centerX,
                                   fromParameter: ParameterID.centerX.rawValue,
                                   at: renderTime)

        var centerY: Double = 0.5
        try paramAPI.getFloatValue(&centerY,
                                   fromParameter: ParameterID.centerY.rawValue,
                                   at: renderTime)

        var rotationDeg: Double = 0.0
        try paramAPI.getFloatValue(&rotationDeg,
                                   fromParameter: ParameterID.rotation.rawValue,
                                   at: renderTime)

        var motionBlurEnabled: Bool = true
        try paramAPI.getBoolValue(&motionBlurEnabled,
                                  fromParameter: ParameterID.motionBlur.rawValue,
                                  at: renderTime)

        var blurSamples: Int = 16
        try paramAPI.getIntValue(&blurSamples,
                                 fromParameter: ParameterID.blurSamples.rawValue,
                                 at: renderTime)

        var easingValue: Int = 3
        try paramAPI.getIntValue(&easingValue,
                                 fromParameter: ParameterID.easingCurve.rawValue,
                                 at: renderTime)
        let easing = EasingCurve(rawValue: easingValue) ?? .easeInOut

        var bounceFactor: Double = 0.3
        try paramAPI.getFloatValue(&bounceFactor,
                                   fromParameter: ParameterID.bounceFactor.rawValue,
                                   at: renderTime)

        var chromaticAmount: Double = 0.0
        try paramAPI.getFloatValue(&chromaticAmount,
                                   fromParameter: ParameterID.chromatic.rawValue,
                                   at: renderTime)

        var vignetteAmount: Double = 0.3
        try paramAPI.getFloatValue(&vignetteAmount,
                                   fromParameter: ParameterID.vignetteAmount.rawValue,
                                   at: renderTime)

        // Apply easing to progress
        let easedProgress = applyEasing(progress, curve: easing, bounce: bounceFactor)

        // Compute zoom and opacity for each source based on style
        let (scaleA, scaleB, opacityA, opacityB, rotA, rotB) =
            computeTransformForStyle(style,
                                     progress: easedProgress,
                                     maxZoom: Float(zoomScale),
                                     maxRotation: Float(rotationDeg))

        // Build uniform data for Metal shader
        var uniforms = ZoomUniforms(
            scaleA: scaleA,
            scaleB: scaleB,
            opacityA: opacityA,
            opacityB: opacityB,
            rotationA: rotA,
            rotationB: rotB,
            centerX: Float(centerX),
            centerY: Float(centerY),
            progress: Float(easedProgress),
            motionBlurEnabled: motionBlurEnabled ? 1 : 0,
            blurSamples: Int32(blurSamples),
            chromaticAberration: Float(chromaticAmount),
            vignetteAmount: Float(vignetteAmount),
            maxZoom: Float(zoomScale)
        )

        // Render using Metal
        try renderWithMetal(destination: destinationImage,
                           sourceA: sourceImages[0],
                           sourceB: sourceImages[1],
                           uniforms: &uniforms)
    }

    // MARK: - Easing Functions

    private func applyEasing(_ t: Double, curve: EasingCurve, bounce: Double) -> Double {
        let clamped = max(0.0, min(1.0, t))

        switch curve {
        case .linear:
            return clamped

        case .easeIn:
            return clamped * clamped * clamped

        case .easeOut:
            let inv = 1.0 - clamped
            return 1.0 - (inv * inv * inv)

        case .easeInOut:
            if clamped < 0.5 {
                return 4.0 * clamped * clamped * clamped
            } else {
                let f = -2.0 * clamped + 2.0
                return 1.0 - (f * f * f) / 2.0
            }

        case .exponential:
            if clamped == 0.0 { return 0.0 }
            if clamped == 1.0 { return 1.0 }
            if clamped < 0.5 {
                return pow(2.0, 20.0 * clamped - 10.0) / 2.0
            } else {
                return (2.0 - pow(2.0, -20.0 * clamped + 10.0)) / 2.0
            }

        case .elastic:
            if clamped == 0.0 { return 0.0 }
            if clamped == 1.0 { return 1.0 }
            let period = 0.3 * (1.0 + bounce)
            let s = period / 4.0
            if clamped < 0.5 {
                let adjusted = 2.0 * clamped - 1.0
                return -0.5 * pow(2.0, 10.0 * adjusted)
                    * sin((adjusted - s) * (2.0 * .pi) / period)
            } else {
                let adjusted = 2.0 * clamped - 1.0
                return pow(2.0, -10.0 * adjusted)
                    * sin((adjusted - s) * (2.0 * .pi) / period) * 0.5 + 1.0
            }
        }
    }

    // MARK: - Style-Based Transform Computation

    private func computeTransformForStyle(
        _ style: ZoomStyle,
        progress: Double,
        maxZoom: Float,
        maxRotation: Float
    ) -> (scaleA: Float, scaleB: Float,
          opacityA: Float, opacityB: Float,
          rotA: Float, rotB: Float)
    {
        let p = Float(progress)

        switch style {
        case .zoomIn:
            // A scales up from 1x to maxZoom, fades out
            // B sits at 1x behind, fades in
            let scaleA = 1.0 + (maxZoom - 1.0) * p
            let scaleB: Float = 1.0
            let opacityA = 1.0 - smoothstep(0.3, 0.9, p)
            let opacityB = smoothstep(0.1, 0.7, p)
            let rotA = maxRotation * p
            let rotB: Float = 0.0
            return (scaleA, scaleB, opacityA, opacityB, rotA, rotB)

        case .zoomOut:
            // A shrinks from 1x to near 0, fades out
            // B sits at 1x behind, fades in
            let scaleA = 1.0 - 0.9 * p
            let scaleB: Float = 1.0
            let opacityA = 1.0 - smoothstep(0.2, 0.8, p)
            let opacityB = smoothstep(0.2, 0.8, p)
            let rotA = -maxRotation * p
            let rotB: Float = 0.0
            return (scaleA, scaleB, opacityA, opacityB, rotA, rotB)

        case .zoomThrough:
            // A zooms in, at midpoint B zooms out from maxZoom to 1x
            if p < 0.5 {
                let subP = p / 0.5
                let scaleA = 1.0 + (maxZoom - 1.0) * subP
                let scaleB = maxZoom
                let opacityA = 1.0 - smoothstep(0.3, 0.8, subP)
                let opacityB: Float = 0.0
                let rotA = maxRotation * subP
                let rotB: Float = maxRotation
                return (scaleA, scaleB, opacityA, opacityB, rotA, rotB)
            } else {
                let subP = (p - 0.5) / 0.5
                let scaleA = maxZoom
                let scaleB = maxZoom - (maxZoom - 1.0) * subP
                let opacityA: Float = 0.0
                let opacityB = smoothstep(0.0, 0.5, subP)
                let rotA: Float = maxRotation
                let rotB = maxRotation * (1.0 - subP)
                return (scaleA, scaleB, opacityA, opacityB, rotA, rotB)
            }

        case .whipZoom:
            // Ultra-fast zoom with heavy motion blur
            let scaleA = 1.0 + (maxZoom * 2.0 - 1.0) * p * p
            let scaleB = max(1.0, maxZoom * 2.0 * (1.0 - p) * (1.0 - p))
            let opacityA = 1.0 - smoothstep(0.2, 0.5, p)
            let opacityB = smoothstep(0.5, 0.8, p)
            let rotA = maxRotation * p * 2.0
            let rotB = -maxRotation * (1.0 - p) * 2.0
            return (scaleA, scaleB, opacityA, opacityB, rotA, rotB)
        }
    }

    // MARK: - Utility

    private func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
        return t * t * (3.0 - 2.0 * t)
    }

    // MARK: - Metal Rendering

    private func renderWithMetal(destination: FxImageTile,
                                 sourceA: FxImageTile,
                                 sourceB: FxImageTile,
                                 uniforms: inout ZoomUniforms) throws {
        guard let deviceAPI = apiManager?.api(for: FxMetalDeviceAPI_v1.self)
                as? FxMetalDeviceAPI_v1 else {
            throw NSError(domain: "ZoomTransition", code: -5,
                          userInfo: [NSLocalizedDescriptionKey: "Metal device API unavailable"])
        }

        let device = deviceAPI.deviceForCurrentRender()
        let commandQueue = device.makeCommandQueue()!

        guard let library = try? device.makeDefaultLibrary(bundle: Bundle(for: type(of: self))),
              let kernelFunction = library.makeFunction(name: "zoomTransitionKernel") else {
            throw NSError(domain: "ZoomTransition", code: -6,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to load Metal shader"])
        }

        let pipelineState = try device.makeComputePipelineState(function: kernelFunction)
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeComputeCommandEncoder()!

        encoder.setComputePipelineState(pipelineState)

        // Set textures
        let textureA = sourceA.metalTexture(forDevice: device)
        let textureB = sourceB.metalTexture(forDevice: device)
        let textureDst = destination.metalTexture(forDevice: device)

        encoder.setTexture(textureA, index: 0)
        encoder.setTexture(textureB, index: 1)
        encoder.setTexture(textureDst, index: 2)

        // Set uniforms
        encoder.setBytes(&uniforms, length: MemoryLayout<ZoomUniforms>.stride, index: 0)

        // Dispatch threads
        let width = destination.imagePixelBounds.width
        let height = destination.imagePixelBounds.height
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (Int(width) + 15) / 16,
            height: (Int(height) + 15) / 16,
            depth: 1
        )

        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
