// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StringScanner",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
        .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "StringScanner",
            targets: ["StringScanner"]),
    ],
    targets: [
        .target(
            name: "StringScanner",
            dependencies: []),
        .testTarget(
            name: "StringScannerTests",
            dependencies: ["StringScanner"]),
    ]
)
