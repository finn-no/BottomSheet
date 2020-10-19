// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "FINNBottomSheet",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "FINNBottomSheet", targets: ["FINNBottomSheet"])
    ],
    targets: [
        .target(name: "FINNBottomSheet", path: "Sources")
    ],
    swiftLanguageVersions: [.v5]
)
