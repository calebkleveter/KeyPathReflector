// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "KeyPathReflector",
    products: [
        .library(name: "KeyPathReflector", targets: ["KeyPathReflector"]),
    ],
    dependencies: [
        .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "KeyPathReflector", dependencies: ["Runtime"]),
        .testTarget(name: "KeyPathReflectorTests", dependencies: ["KeyPathReflector"]),
    ]
)
