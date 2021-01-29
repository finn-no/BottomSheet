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
pod "FINNBottomSheet", git: "https://github.com/finn-no/BottomSheet.git"
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

## Create new releases

### Setup
- Install dependencies with `bundle install` (dependencies will be installed in `./bundler`)
- Fastlane will use the GitHub API, so make sure to create a personal access token [here](https://github.com/settings/tokens) and place it within an environment variable called **`FINN_GITHUB_COM_ACCESS_TOKEN`**.
  - When creating a token, you only need to give access to the scope `repo`.
  - There are multiple ways to make an environment variable, for example by using a `.env` file or adding it to `.bashrc`/`.bash_profile`). Don't forget to run `source .env` (for whichever file you set the environment variables in) if you don't want to restart your shell.
  - Run `bundle exec fastlane verify_environment_variable` to see if it is configured correctly.
- Run `bundle exec fastlane verify_ssh_to_github` to see if ssh to GitHub is working.

### Make release
- Run `bundle exec fastlane` and choose appropriate lane. Follow instructions, you will be asked for confirmation before all remote changes.
- After the release has been created you can edit the description on GitHub by using the printed link.

## Interesting things

### Changelogs

This project has a `Gemfile` that specify some development dependencies, one of those is `pr_changelog` which is a tool that helps you to generate changelogs from the Git history of the repo. You install this by running `bundle install`.

To get the changes that have not been released yet just run:

```
$ pr_changelog
```

If you want to see what changes were released in the last version, run:

```
$ pr_changelog --last-release
```

You can always run the command with the `--help` flag when needed.
