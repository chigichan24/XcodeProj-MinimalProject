// swift-tools-version:6.0.0

import PackageDescription

let package = Package(
    name: "Stock",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj.git", exact: "9.11.0"),
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMinor(from: "1.0.1")),
    ],
    targets: [
        .executableTarget(
            name: "Stock",
            dependencies: [
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "PathKit", package: "PathKit"),
            ]
        ),
    ]
)
