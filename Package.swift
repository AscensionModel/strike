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
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0")
    ],
    targets: [
        .executableTarget(
            name: "Strike",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/Strike",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
