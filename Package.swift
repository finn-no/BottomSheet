// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "BottomSheet",                  
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "BottomSheet", targets: ["BottomSheet"])
    ],
    targets: [
        .target(name: "BottomSheet", path: "Sources")
    ],
    swiftLanguageVersions: [.v5]
)
