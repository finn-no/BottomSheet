//
//  BottomSheet.swift
//  bottom-sheet-delegate
//
//  Created by Granheim Brustad , Henrik on 01/11/2019.
//  Copyright © 2019 Henrik Brustad. All rights reserved.
//

import UIKit

final class BottomSheetTransitioningDelegate: NSObject {
    private let heights: [CGFloat]
    private var presentationController: BottomSheetPresentationController?

    // MARK: - Init

    init(heights: [CGFloat]) {
        self.heights = heights
    }

    convenience init<T: RawRepresentable>(heights: [T]) where T.RawValue == CGFloat {
        self.init(heights: heights.map { $0.rawValue })
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension BottomSheetTransitioningDelegate: UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        presentationController = BottomSheetPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            heights: heights
        )
        return presentationController
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        presentationController?.transitionState = .presenting
        return presentationController
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationController?.transitionState = .dismissing
        return presentationController
    }

    func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return presentationController
    }

//    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
//        return nil
//    }
}
