//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

public final class BottomSheetTransitioningDelegate: NSObject {
    private var contentHeights: [CGFloat]
    private let startTargetIndex: Int
    private let useSafeAreaInsets: Bool
    private var weakPresentationController: WeakRef<BottomSheetPresentationController>?

    private var presentationController: BottomSheetPresentationController? {
        return weakPresentationController?.value
    }

    // MARK: - Init

    public init(contentHeights: [CGFloat], startTargetIndex: Int = 0, useSafeAreaInsets: Bool = false) {
        self.contentHeights = contentHeights
        self.startTargetIndex = startTargetIndex
        self.useSafeAreaInsets = useSafeAreaInsets
    }

    // MARK: - Public

    public func reset() {
        presentationController?.reset()
    }

    public func reload(with contentHeights: [CGFloat]) {
        self.contentHeights = contentHeights
        presentationController?.reload(with: contentHeights)
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension BottomSheetTransitioningDelegate: UIViewControllerTransitioningDelegate {
    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let presentationController = BottomSheetPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            contentHeights: contentHeights,
            startTargetIndex: startTargetIndex,
            useSafeAreaInsets: useSafeAreaInsets
        )
        self.weakPresentationController = WeakRef(value: presentationController)
        return presentationController
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        presentationController?.transitionState = .presenting
        return presentationController
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationController?.transitionState = .dismissing
        return presentationController
    }

    public func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return presentationController
    }
}

// MARK: - Private types

private class WeakRef<T> where T: AnyObject {
    private(set) weak var value: T?

    init(value: T?) {
        self.value = value
    }
}
