// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SSNet",
    platforms: [
        .iOS(.v13)
    ],
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
                .target(name: "libsslocal")
            ],
            path: "Sources",
            exclude: ["HTTPDNS"],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "HTTPDNS",
            path: "Sources/HTTPDNS"
        ),
        .binaryTarget(
            name: "libsslocal",
            path: "xcframeworks/libsslocal.xcframework"
        )
    ]
)
