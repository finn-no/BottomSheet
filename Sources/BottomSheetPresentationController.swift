//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

extension BottomSheetPresentationController {
    enum TransitionState {
        case presenting
        case dismissing
    }
}

final class BottomSheetPresentationController: UIPresentationController {

    // MARK: - Internal properties

    var transitionState: TransitionState?

    // MARK: - Private properties

    private let targetHeights: [CGFloat]
    private let startTargetIndex: Int
    private var bottomSheetView: BottomSheetView?

    // MARK: - Init

    init(
        presentedViewController: UIViewController,
        presenting: UIViewController?,
        targetHeights: [CGFloat],
        startTargetIndex: Int
    ) {
        self.targetHeights = targetHeights
        self.startTargetIndex = startTargetIndex
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    // MARK: - Transition life cycle

    override func presentationTransitionWillBegin() {
        guard transitionState == .presenting else { return }
        createBottomSheetView()
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        guard transitionState == nil else { return }
        guard let containerView = containerView else { return }

        createBottomSheetView()

        bottomSheetView?.present(
            in: containerView,
            targetIndex: startTargetIndex,
            animated: false
        )
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let presentedView = presentedView else { return .zero }
        guard let containerView = containerView else { return .zero }

        let contentHeight = BottomSheetCalculator.contentHeight(
            for: presentedView,
            in: containerView,
            height: targetHeights[startTargetIndex]
        )

        let size = CGSize(
            width: containerView.frame.width,
            height: contentHeight
        )

        return CGRect(
            origin: .zero,
            size: size
        )
    }

    private func createBottomSheetView() {
        guard let presentedView = presentedView else { return }

        bottomSheetView = BottomSheetView(
            contentView: presentedView,
            targetHeights: targetHeights,
            isDismissible: true
        )

        bottomSheetView?.delegate = self
        bottomSheetView?.isDimViewHidden = false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in self.bottomSheetView?.reset() }, completion: nil)
    }
}

// MARK: - UIViewControllerAnimatedTransitioning

extension BottomSheetPresentationController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let completion = { (didComplete: Bool) in
            transitionContext.completeTransition(didComplete)
        }

        switch transitionState {
        case .presenting:
            bottomSheetView?.present(
                in: transitionContext.containerView,
                targetIndex: startTargetIndex,
                completion: completion
            )
        case .dismissing:
            bottomSheetView?.dismiss(completion: completion)

        case .none:
            return
        }
    }
}

// MARK: - UIViewControllerInteractiveTransitioning

extension BottomSheetPresentationController: UIViewControllerInteractiveTransitioning {
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        animateTransition(using: transitionContext)
    }
}

// MARK: - BottomSheetViewPresenterDelegate

extension BottomSheetPresentationController: BottomSheetViewDelegate {
    func bottomSheetViewDidReachDismissArea(_ view: BottomSheetView) {
        presentedViewController.dismiss(animated: true)
    }
}
