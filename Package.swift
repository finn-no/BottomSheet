// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "FINNBottomSheet",
    defaultLocalization: "en",
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
