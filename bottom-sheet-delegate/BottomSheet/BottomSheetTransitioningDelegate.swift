//
//  BottomSheet.swift
//  bottom-sheet-delegate
//
//  Created by Granheim Brustad , Henrik on 01/11/2019.
//  Copyright © 2019 Henrik Brustad. All rights reserved.
//

import UIKit

final class BottomSheetTransitioningDelegate: NSObject {
    private let preferredHeights: [CGFloat]
    private var presentationController: BottomSheetPresentationController?

    // MARK: - Init

    init(preferredHeights: [CGFloat]) {
        self.preferredHeights = preferredHeights
    }

    convenience init<T: RawRepresentable>(preferredHeights: [T]) where T.RawValue == CGFloat {
        self.init(preferredHeights: preferredHeights.map { $0.rawValue })
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
            preferredHeights: preferredHeights
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
}
