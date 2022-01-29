// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "AsyncHotStream",
    platforms: [.macOS(.v10_15), .iOS(.v13), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(
            name: "AsyncHotStream",
            targets: ["AsyncHotStream"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "AsyncHotStream",
            dependencies: [],
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-warn-concurrency",
                    "-Xfrontend", "-enable-actor-data-race-checks",
                ])
            ]
        ),
        .testTarget(
            name: "AsyncHotStreamTests",
            dependencies: ["AsyncHotStream"],
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-warn-concurrency",
                    "-Xfrontend", "-enable-actor-data-race-checks",
                ])
            ]
        ),
    ]
)
