// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Winamp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Winamp", targets: ["Winamp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Winamp",
            dependencies: [],
            path: "Sources"
        )
    ]
)

