// swift-tools-version: 5.9
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
