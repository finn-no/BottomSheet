<img src="/GitHub/bottom-sheet-banner.png">

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
.package(name: "FINNBottomSheet", url: "https://github.com/finn-no/BottomSheet.git", .upToNextMajor(from: "1.0.0"))
```

## Usage

View controller -based presentation:

```swift
import FINNBottomSheet

let transitioningDelegate = BottomSheetTransitioningDelegate(
    contentHeights: [.bottomSheetAutomatic, UIScreen.main.bounds.size.height - 200],
    startTargetIndex: 0
)
let viewController = UIViewController()
viewController.transitioningDelegate = transitioningDelegate
viewController.modalPresentationStyle = .custom

present(viewController, animated: true)
```

View -based presentation:

```swift
import FINNBottomSheet

let contentView = UIView()
contentView.backgroundColor = .red

let bottomSheetView = BottomSheetView(
    contentView: contentView,
    contentHeights: [100, 500]
)

// Can be presented in any UIView subclass
bottomSheetView.present(in: viewController.view, targetIndex: 0)
```

## Known limitations

### Using `.bottomSheetAutomatic`:

When using `.bottomSheetAutomatic` to calculate the content height and your view is constrained using the `layoutMarginsGuide`, you must be aware that the returned content height may actually be higher than the compressed layout size of your view. Also, it may result in the transition animation freezing. This problem is avoided simply by not using the `layoutMarginsGuide`.

### BottomSheetTransitioningDelegate

To avoid "glitches" you might need to keep a strong reference to the transitioning delegate (`BottomSheetTransitioningDelegate`) until the bottom sheet animation is complete. 
