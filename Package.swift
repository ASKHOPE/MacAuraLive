// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacAura",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacAura",
            targets: ["MacAura"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacAura",
            dependencies: [],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
