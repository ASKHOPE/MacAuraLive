// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacAuraLive",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacAuraLive",
            targets: ["MacAuraLive"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacAuraLive",
            dependencies: [],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
