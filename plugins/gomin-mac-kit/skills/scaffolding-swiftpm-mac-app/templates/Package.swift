// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MyApp",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MyApp", targets: ["MyApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MyApp",
            path: "Sources/MyApp",
            // Info.plist is copied by scripts/build-app.sh, not compiled in
            exclude: ["Info.plist"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "MyAppTests",
            dependencies: ["MyApp"],
            path: "Tests/MyAppTests"
        )
    ]
)
