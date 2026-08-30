// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MacProductivitySuite",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "AppEngine",
            dependencies: [],
            path: "src/NativeStandaloneApp",
            exclude: ["Info.plist"],
            swiftSettings: [
                .unsafeFlags(["-F", "Frameworks", "-parse-as-library"])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F", "Frameworks",
                    "-Xlinker", "-rpath", "-Xlinker", "Frameworks"
                ]),
                .linkedFramework("Cocoa"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Carbon"),
                .linkedFramework("Sparkle")
            ]
        ),
        .testTarget(
            name: "MacProductivitySuiteTests",
            dependencies: [
                "AppEngine",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "tests",
            exclude: ["run_tests.sh"]
        )
    ]
)
