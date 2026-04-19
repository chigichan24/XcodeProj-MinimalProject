// swift-tools-version:6.0.0

import PackageDescription

let package = Package(
    name: "Branch",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(path: "../../XcodeProj"),
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMinor(from: "1.0.1")),
    ],
    targets: [
        .executableTarget(
            name: "Branch",
            dependencies: [
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "PathKit", package: "PathKit"),
            ]
        ),
    ]
)
