// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "combine-schedulers",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "CombineSchedulers",
            targets: ["CombineSchedulers"]
        ),
    ],
    traits: packageTraits(),
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.2.2"),
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0"),
    ],
    targets: [
        .target(
            name: "CombineSchedulers",
            dependencies: [
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
                .product(name: "OpenCombineShim", package: "OpenCombine", condition: .when(platforms: [.linux], traits: ["OpenCombineSchedulers"])),
            ]
        ),
        .testTarget(
            name: "CombineSchedulersTests",
            dependencies: [
                "CombineSchedulers",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

func packageTraits() -> Set<Trait> {
    let traits: Set<Trait> = [
        Trait(
            name: "OpenCombineSchedulers",
            description: "Drop in replacement for Combine on non Darwin platforms",
            enabledTraits: []
        )
    ]
    #if os(Linux)
        return traits + [.default(enabledTraits: ["OpenCombineSchedulers"])]
    #else
        return traits
    #endif
}
