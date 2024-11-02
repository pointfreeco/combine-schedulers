// swift-tools-version: 6.0

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
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", branch: "main"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.2.2"),
    .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0")
  ],
  targets: [
    .target(
      name: "CombineSchedulers",
      dependencies: [
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
        .product(name: "OpenCombineShim", package: "OpenCombine"),
        .product(name: "OpenCombineFoundation", package: "OpenCombine"),
        .product(name: "OpenCombineDispatch", package: "OpenCombine"),
      ]
    ),
    .testTarget(
      name: "CombineSchedulersTests",
      dependencies: [
        "CombineSchedulers",
        .product(name: "OpenCombineShim", package: "OpenCombine"),
        .product(name: "OpenCombineFoundation", package: "OpenCombine"),
        .product(name: "OpenCombineDispatch", package: "OpenCombine")
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
