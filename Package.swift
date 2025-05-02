// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "OpenPanel",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "OpenPanel",
            targets: ["OpenPanel"]),
    ],
    targets: [
        .target(
            name: "OpenPanel",
            path: "OpenPanel-Swift-SDK")
    ]
)
