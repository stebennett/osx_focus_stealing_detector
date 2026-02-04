// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FocusStealer",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "FocusStealer",
            path: "Sources/FocusStealer"
        ),
        .executableTarget(
            name: "FocusStealerTests",
            path: "Tests/FocusStealerTests"
        )
    ]
)
