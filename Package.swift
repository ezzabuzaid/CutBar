// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CutBar",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "CutBar",
            targets: ["CutBar"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "CutBar",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            resources: [
                .copy("Resources/Fonts"),
                .process("Resources/Assets.xcassets"),
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3"),
            ]
        ),
        .testTarget(
            name: "CutBarTests",
            dependencies: ["CutBar"]
        ),
    ]
)
