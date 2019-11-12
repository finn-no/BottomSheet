//
//  BottomSheet.swift
//  bottom-sheet-delegate
//
//  Created by Granheim Brustad , Henrik on 01/11/2019.
//  Copyright © 2019 Henrik Brustad. All rights reserved.
//

import UIKit

struct BottomSheetState: Equatable {
    static let automatic = BottomSheetState(id: -123456789, height: 0)

    let id: Int
    let height: CGFloat

    init(id: Int, height: CGFloat) {
        self.id = id
        self.height = height
    }

    func height(for view: UIView, targetSize: CGSize) -> CGFloat {
        guard self == .automatic else {
            return height
        }

        return view.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        ).height
    }
}

struct BottomSheetConfiguration {
    let states: [BottomSheetState]
    let threshold: CGFloat

    init(states: [BottomSheetState] = [.automatic], threshold: CGFloat = 75) {
        self.states = states.isEmpty ? [.automatic] : states
        self.threshold = threshold
    }

    func state(for location: CGPoint, in targetSize: CGSize) -> BottomSheetState? {
        let value: (BottomSheetState) -> CGFloat = { abs(targetSize.height - $0.height - location.y) }
        return states.min(by: { value($0) < value($1) })
    }
}

class BottomSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    private let config: BottomSheetConfiguration
    private var presentationController: BottomSheetPresentationController?

    init(config: BottomSheetConfiguration) {
        self.config = config
    }

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        presentationController = BottomSheetPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            config: config
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
