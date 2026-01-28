// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacAmp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacAmp", targets: ["MacAmp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacAmp",
            dependencies: [],
            path: "Sources"
        )
    ]
)

