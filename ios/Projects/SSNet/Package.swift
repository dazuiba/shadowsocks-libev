// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "SSNet",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "SSNet",
            targets: ["SSNet"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SSNet",
            dependencies: [
                "SSNetOC",
                .target(name: "libsslocal"),
                .target(name: "MSDKDns_C11")
            ],
            path: "Sources",
            exclude: ["Objective-C"],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SSNetOC",
            dependencies:[],
            path: "Sources/Objective-C",
            publicHeadersPath:"include"
        ),
        .binaryTarget(
            name: "libsslocal",
            path: "xcframeworks/libsslocal.xcframework"
        ),
        .binaryTarget(
            name: "MSDKDns_C11",
            path: "xcframeworks/MSDKDns_C11.xcframework"
        ),
        .testTarget(
            name: "SSNetTests",
            dependencies: ["SSNet"],
            path: "Tests"
        )
    ]
)
