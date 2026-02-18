// ZoomTransitionFactory.swift
// Plugin factory and FxPlug entry point for the Zoom Transition plugin.

import Foundation
import FxPlug

// MARK: - Plugin Factory

@objc class ZoomTransitionFactory: NSObject, FxPluginFactory {

    /// Unique identifier for this plugin — registered with FCP.
    static let pluginUUID = "com.themeek.fcpx.zoom-transition"

    /// Human-readable name shown in FCPX's transitions browser.
    static let pluginName = "Modern Zoom"

    /// Category under which the transition appears.
    static let pluginCategory = "The Meek"

    // MARK: - FxPluginFactory Protocol

    func pluginClassForIdentifier(_ identifier: String) -> AnyClass? {
        if identifier == ZoomTransitionFactory.pluginUUID {
            return ZoomTransition.self
        }
        return nil
    }

    func pluginIdentifiers() -> [String] {
        return [ZoomTransitionFactory.pluginUUID]
    }

    func pluginDisplayName(for identifier: String) -> String? {
        if identifier == ZoomTransitionFactory.pluginUUID {
            return ZoomTransitionFactory.pluginName
        }
        return nil
    }

    func pluginCategory(for identifier: String) -> String? {
        if identifier == ZoomTransitionFactory.pluginUUID {
            return ZoomTransitionFactory.pluginCategory
        }
        return nil
    }

    func pluginType(for identifier: String) -> FxPlugType {
        return .transition
    }

    func pluginVersion(for identifier: String) -> UInt32 {
        return 1
    }

    func minimumHostVersion(for identifier: String) -> UInt32 {
        // FCP 10.8+ / FCP 12
        return 5
    }

    func pluginIconName(for identifier: String) -> String? {
        return "ZoomTransitionIcon"
    }

    func pluginThumbnailName(for identifier: String) -> String? {
        return "ZoomTransitionThumbnail"
    }
}

// MARK: - Principal Class Registration

/// This function is called by the FxPlug host (Final Cut Pro / Motion)
/// to discover plugins in this bundle.
@objc(ZoomTransitionPluginEntry)
class ZoomTransitionPluginEntry: NSObject {

    @objc static func fxPluginFactories() -> [FxPluginFactory] {
        return [ZoomTransitionFactory()]
    }
}
