//
//  BottomSheet.swift
//  bottom-sheet-delegate
//
//  Created by Granheim Brustad , Henrik on 01/11/2019.
//  Copyright © 2019 Henrik Brustad. All rights reserved.
//

import UIKit

struct BottomSheetConfiguration {
    let compactModel: BottomSheetModel
    let expandedModel: BottomSheetModel?
}

class BottomSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    private let configuration: BottomSheetConfiguration
    private var presentationController: BottomSheetPresentationController?

    init(configuration: BottomSheetConfiguration) {
        self.configuration = configuration
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        presentationController = BottomSheetPresentationController(
            presentedViewController: presented,
            presenting: presenting
        )

        presentationController?.addModel(configuration.compactModel, for: .compact)
        presentationController?.addModel(configuration.expandedModel, for: .expanded)

        return presentationController
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationController?.transitionState = .presenting
        return presentationController
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationController?.transitionState = .dismissing
        return presentationController
    }

    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return presentationController
    }

//    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
//        return nil
//    }
}
