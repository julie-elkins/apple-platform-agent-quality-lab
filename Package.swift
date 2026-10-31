// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AppleAgentQualityLab",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "apple-agent-quality-lab",
            targets: ["AppleAgentQualityLab"]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppleAgentQualityLab"
        ),
        .testTarget(
            name: "AppleAgentQualityLabTests",
            dependencies: ["AppleAgentQualityLab"]
        )
    ]
)
