// swift-tools-version:5.9
// Package.swift
//
// Swift Package Manager manifest for building the Modern Zoom Transition
// FxPlug plugin outside of Xcode (optional — Xcode project is preferred).

import PackageDescription

let package = Package(
    name: "FCPXZoomTransition",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ZoomTransition",
            type: .dynamic,
            targets: ["ZoomTransition"]
        ),
    ],
    targets: [
        .target(
            name: "ZoomTransition",
            path: "Source",
            linkerSettings: [
                .linkedFramework("FxPlug"),
                .linkedFramework("Metal"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("CoreVideo"),
            ]
        ),
    ]
)
