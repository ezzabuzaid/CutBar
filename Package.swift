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
    targets: [
        .executableTarget(
            name: "CutBar",
            resources: [
                .copy("Resources/Fonts"),
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
