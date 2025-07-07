// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "fuzzy",
    products: [
        .library(name: "Fuzzy", targets: ["Fuzzy"]),
    ],
    targets: [
        .target(name: "Fuzzy"),
        .testTarget(
            name: "FuzzyTests",
            dependencies: ["Fuzzy"],
            resources: [.process("Fixtures")]
        ),
    ]
)
