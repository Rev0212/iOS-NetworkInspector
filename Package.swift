// swift-tools-version: 5.9


import PackageDescription

let package = Package(
    name: "NetworkInspector",
    platforms: [
        .iOS(.v14)

    ],
    products: [
        .library(
            name: "NetworkInspector",
            targets: ["NetworkInspector"]
        )
    ],
    targets: [
        .target(
            name: "NetworkInspector",
            dependencies: []
        ),
        .testTarget(
            name: "NetworkInspectorTests",
            dependencies: ["NetworkInspector"]
        )
    ]
)

