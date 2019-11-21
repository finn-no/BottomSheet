//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

public final class BottomSheetTransitioningDelegate: NSObject {
    private let preferredHeights: [CGFloat]
    private let startTargetIndex: Int
    private var presentationController: BottomSheetPresentationController?

    // MARK: - Init

    public init(targetHeights: [CGFloat], startTargetIndex: Int = 0) {
        self.preferredHeights = targetHeights
        self.startTargetIndex = startTargetIndex
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension BottomSheetTransitioningDelegate: UIViewControllerTransitioningDelegate {
    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        presentationController = BottomSheetPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            targetHeights: preferredHeights,
            startTargetIndex: startTargetIndex
        )
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
