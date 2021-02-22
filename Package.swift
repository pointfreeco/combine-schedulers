// swift-tools-version:5.1

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
  targets: [
    .target(name: "CombineSchedulers"),
    .testTarget(
      name: "CombineSchedulersTests",
      dependencies: ["CombineSchedulers"]
    ),
  ]
)
