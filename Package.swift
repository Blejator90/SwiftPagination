// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "swift-pagination",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SwiftPagination",
            targets: ["SwiftPagination"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")

    ],
    targets: [
        .target(
            name: "SwiftPagination"
        ),
        .testTarget(
            name: "SwiftPaginationTests",
            dependencies: [
                "SwiftPagination",
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras")
            ]
        )
    ]
)
