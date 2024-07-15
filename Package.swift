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
    targets: [
        .target(
            name: "SwiftPagination"
        ),
        .testTarget(
            name: "SwiftPaginationTests",
            dependencies: ["SwiftPagination"]
        )
    ]
)
