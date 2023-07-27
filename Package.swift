// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RoborockApi",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "RoborockApi",
            targets: ["RoborockApi"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ThomasHack/NWWebSocket.git", .branchItem("main")),
    ],
    targets: [
        .target(
            name: "RoborockApi",
            dependencies: ["NWWebSocket"])
    ]
)
