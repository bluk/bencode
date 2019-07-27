// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bencode",
    products: [
        .library(
            name: "Bencode",
            targets: ["Bencode"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Bencode",
            dependencies: []),
        .testTarget(
            name: "BencodeTests",
            dependencies: ["Bencode"]),
    ]
)
