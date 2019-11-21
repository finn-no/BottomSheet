# BottomSheet
[![CircleCI](https://img.shields.io/circleci/project/github/finn-no/BottomSheet/master.svg)](https://circleci.com/gh/finn-no/BottomSheet/tree/master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/FINNBottomSheet.svg)](https://cocoapods.org/pods/FINNBottomSheet)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

**BottomSheet** is an implementation of custom modal presentation style for thumb-friendly interactive views anchored to the bottom of the screen.

- [x] Custom `UIViewControllerTransitioningDelegate` for dismissable modal bottom sheets
- [x] `BottomSheetView` for displaying complementary content as a standard bottom sheet view
- [x] Expanding bottom sheets with multiple states to transition between
- [x] Support for automatic view height based on Auto Layout constraints
- [x] Beatiful spring animation

## Demo

<p align="center">
  <img src="/GitHub/demo.gif"/>
</p>

## Installation

**BottomSheet** is available through [Carthage](https://github.com/Carthage/Carthage). Append this line to your `Cartfile`:

```ruby
github "finn-no/BottomSheet"
```

**BottomSheet** is also available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'FINNBottomSheet'
```

To integrate using Apple's Swift package manager, add the following as a dependency to your Package.swift:

```swift
.package(url: "https://github.com/finn-no/BottomSheet.git", .upToNextMajor(from: "1.0.0"))
```

## Usage

View controller -based presentation:

```swift
let transitioningDelegate = BottomSheetTransitioningDelegate(
    targetHeights: [.bottomSheetAutomatic, UIScreen.main.bounds.size.height - 200],
    startTargetIndex: 0
)
let viewController = UIViewController()
viewController.transitioningDelegate = transitioningDelegate
viewController.modalPresentationStyle = .custom

present(viewController, animated: true)
```

View -based presentation:

```swift
let contentView = UIView()
contentView.backgroundColor = .red

let bottomSheetView = BottomSheetView(
    contentView: contentView,
    targetHeights: [100, 500]
)

// Can be presented in any UIView subclass
bottomSheetView.present(in: viewController.view, targetIndex: 0) 
```