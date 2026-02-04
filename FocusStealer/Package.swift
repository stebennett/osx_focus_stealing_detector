// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FocusStealer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "FocusStealerLib",
            targets: ["FocusStealerLib"]
        )
    ],
    targets: [
        .target(
            name: "FocusStealerLib",
            path: "Sources/FocusStealerLib"
        ),
        .executableTarget(
            name: "FocusStealer",
            dependencies: ["FocusStealerLib"],
            path: "Sources/FocusStealer"
        ),
        .executableTarget(
            name: "FocusStealerTests",
            dependencies: ["FocusStealerLib"],
            path: "Tests/FocusStealerTests"
        )
    ]
)
