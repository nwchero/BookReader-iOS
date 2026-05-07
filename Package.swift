import PackageDescription

let package = Package(
    name: "BookReader",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "BookReader",
            targets: ["BookReader"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.1"),
    ],
    targets: [
        .target(
            name: "BookReader",
            dependencies: [
                .product(name: "SwiftSoup", package: "SwiftSoup"),
            ]),
        .testTarget(
            name: "BookReaderTests",
            dependencies: ["BookReader"]),
    ]
)
