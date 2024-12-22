// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Engine",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Engine",
            targets: ["CEngine-xcframework",  "Engine"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "CEngine-xcframework",
            path: "CEngine.xcframework"
        ),
        .target(
            name: "Engine",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedLibrary("sqlite3"),
            ]
        )
    ],
    cxxLanguageStandard: CXXLanguageStandard.cxx17
)