// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "AgenticPrograms",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "AgenticPrograms",
            targets: [
                "AgenticPrograms",
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/Agentic.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Primitives.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Schema.git",
            branch: "master"
        ),
    ],
    targets: [
        .target(
            name: "AgenticPrograms",
            dependencies: [
                .product(
                    name: "Agentic",
                    package: "Agentic"
                ),
                .product(
                    name: "Primitives",
                    package: "Primitives"
                ),
                .product(
                    name: "Schema",
                    package: "Schema"
                ),
            ]
        ),
    ],
    swiftLanguageModes: [
        .v6,
    ]
)
