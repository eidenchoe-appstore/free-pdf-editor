// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FreePDFEditor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FreePDFEditor", targets: ["FreePDFEditor"])
    ],
    targets: [
        .executableTarget(
            name: "FreePDFEditor",
            path: "Sources/FreePDFEditor",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        )
    ]
)
