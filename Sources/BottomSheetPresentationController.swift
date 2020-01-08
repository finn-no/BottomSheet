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

public protocol BottomSheetPresentationControllerDelegate: AnyObject {
    func bottomSheetPresentationController(
        _ controller: UIPresentationController,
        shouldDismissBy action: BottomSheetView.DismissAction
    ) -> Bool

    func bottomSheetPresentationController(
        _ controller: UIPresentationController,
        didCancelDismissBy action: BottomSheetView.DismissAction
    )

    func bottomSheetPresentationController(
        _ controller: UIPresentationController,
        willDismissBy action: BottomSheetView.DismissAction?
    )

    func bottomSheetPresentationController(
        _ controller: UIPresentationController,
        didDismissBy action: BottomSheetView.DismissAction?
    )
}

final class BottomSheetPresentationController: UIPresentationController {

    // MARK: - Internal properties

    var transitionState: TransitionState?

    // MARK: - Private properties

    private var contentHeights: [CGFloat]
    private let startTargetIndex: Int
    private let handleBackground: BottomSheetView.HandleBackground
    private let useSafeAreaInsets: Bool
    private var dismissVelocity: CGPoint = .zero
    private var bottomSheetView: BottomSheetView?
    private var dismissAction: BottomSheetView.DismissAction?
    private weak var presentationDelegate: BottomSheetPresentationControllerDelegate?
    private weak var animationDelegate: BottomSheetViewAnimationDelegate?
    private weak var transitionContext: UIViewControllerContextTransitioning?

    // MARK: - Init

    init(
        presentedViewController: UIViewController,
        presenting: UIViewController?,
        contentHeights: [CGFloat],
        startTargetIndex: Int,
        presentationDelegate: BottomSheetPresentationControllerDelegate?,
        animationDelegate: BottomSheetViewAnimationDelegate?,
        handleBackground: BottomSheetView.HandleBackground,
        useSafeAreaInsets: Bool
    ) {
        self.contentHeights = contentHeights
        self.startTargetIndex = startTargetIndex
        self.handleBackground = handleBackground
        self.presentationDelegate = presentationDelegate
        self.animationDelegate = animationDelegate
        self.useSafeAreaInsets = useSafeAreaInsets
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    // MARK: - Internal

    func transition(to index: Int) {
        bottomSheetView?.transition(to: index)
    }

    func reset() {
        bottomSheetView?.reset()
    }

    func reload(with contentHeights: [CGFloat]) {
        self.contentHeights = contentHeights
        bottomSheetView?.reload(with: contentHeights)
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

    override func dismissalTransitionWillBegin() {
        presentationDelegate?.bottomSheetPresentationController(self, willDismissBy: dismissAction)
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        presentationDelegate?.bottomSheetPresentationController(self, didDismissBy: dismissAction)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let presentedView = presentedView else { return .zero }
        guard let containerView = containerView else { return .zero }

        let contentHeight = BottomSheetCalculator.contentHeight(
            for: presentedView,
            in: containerView,
            height: contentHeights[startTargetIndex],
            useSafeAreaInsets: useSafeAreaInsets
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
            contentHeights: contentHeights,
            handleBackground: handleBackground,
            useSafeAreaInsets: useSafeAreaInsets,
            dismissalDelegate: self,
            animationDelegate: animationDelegate
        )

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
        self.transitionContext = transitionContext

        let completion = { [weak self] (didComplete: Bool) in
            self?.transitionContext?.completeTransition(didComplete)
            self?.transitionState = nil
        }

        switch transitionState {
        case .presenting:
            bottomSheetView?.present(
                in: transitionContext.containerView,
                targetIndex: startTargetIndex,
                completion: completion
            )
        case .dismissing:
            bottomSheetView?.dismiss(
                velocity: dismissVelocity,
                completion: completion
            )

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

extension BottomSheetPresentationController: BottomSheetViewDismissalDelegate {
    func bottomSheetView(_ view: BottomSheetView, willDismissBy action: BottomSheetView.DismissAction) {
        guard presentationDelegate?.bottomSheetPresentationController(self, shouldDismissBy: action) ?? true else {
            //view.reset()
            presentationDelegate?.bottomSheetPresentationController(self, didCancelDismissBy: action)
            return
        }

        dismissAction = action

        switch action {
        case .drag(let velocity):
            dismiss(with: velocity)
        case .tap:
            dismiss(with: .zero)
        }
    }

    private func dismiss(with velocity: CGPoint) {
        switch transitionState {
        case .presenting:
            bottomSheetView?.dismiss(velocity: velocity, completion: { _ in
                self.transitionContext?.completeTransition(false)
            })
        case .dismissing:
            return
        case .none:
            dismissVelocity = velocity
            presentedViewController.dismiss(animated: true)
        }
    }
}
