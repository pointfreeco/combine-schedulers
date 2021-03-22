// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "combine-schedulers",
  platforms: [
    .iOS(.v10),
    .macOS(.v10_12),
    .tvOS(.v10),
    .watchOS(.v3),
  ],
  products: [
    .library(
      name: "CombineSchedulers",
      targets: ["CombineSchedulers"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.1.0"),
  ],
  targets: [
    .target(
      name: "CombineSchedulers",
      dependencies: [
        "XCTestDynamicOverlay",
      ]
    ),
    .testTarget(
      name: "CombineSchedulersTests",
      dependencies: [
        "CombineSchedulers",
      ]
    ),
  ]
)
