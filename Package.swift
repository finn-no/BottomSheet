// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FINNBottomSheet",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "FINNBottomSheet", targets: ["FINNBottomSheet"])
    ],
    targets: [
        .target(name: "FINNBottomSheet", path: "Sources", exclude: ["Info.plist"])
    ]
)
