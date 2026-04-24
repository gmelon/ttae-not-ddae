// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Ttae",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ttae", targets: ["TtaeApp"]),
        .library(name: "TtaeCore", targets: ["TtaeCore"]),
    ],
    targets: [
        .target(
            name: "TtaeCore",
            path: "Sources/TtaeCore"
        ),
        .executableTarget(
            name: "TtaeApp",
            dependencies: ["TtaeCore"],
            path: "Sources/TtaeApp"
        ),
        .testTarget(
            name: "TtaeCoreTests",
            dependencies: ["TtaeCore"],
            path: "Tests/TtaeCoreTests"
        ),
    ]
)
