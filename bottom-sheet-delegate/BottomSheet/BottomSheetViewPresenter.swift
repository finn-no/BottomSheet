//
//  Copyright © FINN AS. All rights reserved.
//

import UIKit

protocol BottomSheetViewPresenterDelegate: AnyObject {
    func bottomSheetViewPresenter(_: BottomSheetViewPresenter, didTransitionTo state: BottomSheetState?)
}

final class BottomSheetViewPresenter {
    private static let handleHeight: CGFloat = 20

    weak var delegate: BottomSheetViewPresenterDelegate?

    // MARK: - Private properties

    private(set) var state: BottomSheetState
    private let config: BottomSheetConfiguration
    private var topConstraint: NSLayoutConstraint!
    private weak var containerView: UIView?
    private weak var bottomSheetView: UIView?

    private lazy var panGesture = UIPanGestureRecognizer(
        target: self,
        action: #selector(handlePan(panGesture:))
    )

    private lazy var springAnimator = SpringAnimator(
        dampingRatio: 0.8,
        frequencyResponse: 0.4
    )

    init(config: BottomSheetConfiguration) {
        self.config = config
        self.state = config.states.first ?? .automatic
    }

    // MARK: - Internal methods

    public func addPresentedView(_ presentedView: UIView, to containerView: UIView) {
        let bottomSheetView = BottomSheetView(contentView: presentedView)
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bottomSheetView)

        topConstraint = bottomSheetView.topAnchor.constraint(
            equalTo: containerView.topAnchor,
            constant: containerView.frame.maxY
        )

        let height = state.height(for: bottomSheetView, targetSize: containerView.frame.size)

        NSLayoutConstraint.activate([
            topConstraint,
            bottomSheetView.bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor),
            bottomSheetView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomSheetView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: height + BottomSheetViewPresenter.handleHeight
            )
        ])

        bottomSheetView.addGestureRecognizer(panGesture)

        springAnimator.addAnimation { [weak self] position in
            self?.topConstraint.constant = position.y
        }

        self.containerView = containerView
        self.bottomSheetView = bottomSheetView

        containerView.layoutIfNeeded()
    }

    func animate(to position: CGPoint) {
        springAnimator.fromPosition = CGPoint(x: 0, y: topConstraint.constant)
        springAnimator.toPosition = position
        springAnimator.initialVelocity = .zero
        springAnimator.startAnimation()
    }

    func addAnimationCompletion(_ completion: @escaping (Bool) -> Void) {
        springAnimator.addCompletion { didComplete in
            completion(didComplete)
        }
    }

    func present() {
        transition(to: state)
    }

    private func transition(to state: BottomSheetState?) {
        guard let bottomSheetView = bottomSheetView, let containerView = containerView else {
            return
        }

        guard let state = state else {
            delegate?.bottomSheetViewPresenter(self, didTransitionTo: nil)
            return
        }

        let containerHeight = containerView.frame.height

        self.state = state
        let height = state.height(for: bottomSheetView, targetSize: containerView.frame.size)
        animate(to: CGPoint(x: 0, y: containerHeight - height))

        delegate?.bottomSheetViewPresenter(self, didTransitionTo: state)
    }

    // MARK: - Private methods

    @objc private func handlePan(panGesture: UIPanGestureRecognizer) {
        guard let containerView = containerView else {
            return
        }

        switch panGesture.state {
        case .began:
            springAnimator.pauseAnimation()
        case .ended, .cancelled, .failed:
            let location = CGPoint(x: 0, y: topConstraint.constant)
            let state = config.state(for: location, in: containerView.frame.size)
            transition(to: state)
        default:
            break
        }

        let translation = panGesture.translation(in: containerView)
        topConstraint.constant += translation.y
        panGesture.setTranslation(.zero, in: containerView)
    }
}
