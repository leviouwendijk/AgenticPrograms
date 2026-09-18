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
        .executable(
            name: "aprogtest",
            targets: [
                "AgenticProgramsTestFlows",
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/Agentic.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/AgenticInference.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/AgenticRecovery.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Primitives.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/TestFlows.git",
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
                    name: "AgenticInference",
                    package: "AgenticInference"
                ),
                .product(
                    name: "AgenticRecovery",
                    package: "AgenticRecovery"
                ),
                .product(
                    name: "Primitives",
                    package: "Primitives"
                ),
            ]
        ),
        .executableTarget(
            name: "AgenticProgramsTestFlows",
            dependencies: [
                "AgenticPrograms",
                .product(
                    name: "Agentic",
                    package: "Agentic"
                ),
                .product(
                    name: "AgenticInference",
                    package: "AgenticInference"
                ),
                .product(
                    name: "Primitives",
                    package: "Primitives"
                ),
                .product(
                    name: "TestFlows",
                    package: "TestFlows"
                ),
            ]
        ),
    ],
    swiftLanguageModes: [
        .v6,
    ]
)
