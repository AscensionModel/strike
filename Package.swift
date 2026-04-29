// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Strike",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Strike", targets: ["Strike"])
    ],
    targets: [
        .executableTarget(
            name: "Strike",
            path: "Sources/Strike",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
