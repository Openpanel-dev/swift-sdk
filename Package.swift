// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "OpenPanel",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "OpenPanel",
            targets: ["OpenPanel"]),
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "OpenPanel",
            dependencies: []),
    ]
)
