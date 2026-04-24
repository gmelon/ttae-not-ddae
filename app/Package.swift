// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TtaeCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "TtaeCore", targets: ["TtaeCore"]),
    ],
    targets: [
        .target(
            name: "TtaeCore",
            path: "Sources/TtaeCore"
        ),
        .testTarget(
            name: "TtaeCoreTests",
            dependencies: ["TtaeCore"],
            path: "Tests/TtaeCoreTests"
        ),
    ]
)
