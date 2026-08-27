// swift-tools-version: 6.4

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
  traits: [
    Trait(
      name: "OpenCombineSchedulers",
      description: "Support for Combine on non-Apple platforms using OpenCombine."
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "2.1.0"),
    .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0"),
  ],
  targets: [
    .target(
      name: "CombineSchedulers",
      dependencies: [
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
        .product(
          name: "OpenCombineShim",
          package: "OpenCombine",
          condition: .when(platforms: [.linux, .android], traits: ["OpenCombineSchedulers"])
        ),
      ]
    ),
    .testTarget(
      name: "CombineSchedulersTests",
      dependencies: [
        "CombineSchedulers"
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)

#if !canImport(Darwin)
  package.traits.insert(
    .default(enabledTraits: ["OpenCombineSchedulers"])
  )
#endif

for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(contentsOf: [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
  ])
}
