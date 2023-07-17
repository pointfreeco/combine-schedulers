// swift-tools-version:5.5

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
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "0.1.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.8.5")
  ],
  targets: [
    .target(
      name: "CombineSchedulers",
      dependencies: [
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
      ]
    ),
    .testTarget(
      name: "CombineSchedulersTests",
      dependencies: [
        "CombineSchedulers"
      ]
    ),
  ]
)
