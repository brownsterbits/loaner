// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LoanerFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LoanerFeature",
            targets: ["LoanerFeature"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package and define a module or a test suite.
        // Targets can depend on other targets in this package and on products from dependencies.
        .target(
            name: "LoanerFeature"
        ),
        .testTarget(
            name: "LoanerFeatureTests",
            dependencies: [
                "LoanerFeature"
            ]
        ),
    ]
)
