// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Roborock-Api",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "Roborock-Api",
            targets: ["Roborock-Api"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pusher/NWWebSocket.git", .upToNextMajor(from: "0.5.2")),
    ],
    targets: [
        .target(
            name: "Roborock-Api",
            dependencies: ["NWWebSocket"])
    ]
)
