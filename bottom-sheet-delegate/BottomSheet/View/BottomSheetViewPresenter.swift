//
//  Copyright © FINN AS. All rights reserved.
//

import UIKit

protocol BottomSheetViewPresenterDelegate: AnyObject {
    func bottomSheetViewPresenter(_: BottomSheetViewPresenter, didTransitionTo state: BottomSheetState?)
}

final class BottomSheetViewPresenter {
    weak var delegate: BottomSheetViewPresenterDelegate?

    // MARK: - Private properties

    private var models: [BottomSheetState: BottomSheetModel] = [:]
    private(set) var state: BottomSheetState = .compact
    private var topConstraint: NSLayoutConstraint!
    private var containerView: UIView?

    private lazy var panGesture = UIPanGestureRecognizer(
        target: self,
        action: #selector(handlePan(panGesture:))
    )

    private lazy var springAnimator = SpringAnimator(
        dampingRatio: 0.8,
        frequencyResponse: 0.4
    )

    // MARK: - Internal methods

    func present(_ presentedView: UIView, in containerView: UIView) {
        guard let compactModel = models[.compact] else { return }

        self.containerView = containerView

        let bottomSheetView = BottomSheetView(contentView: presentedView)
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bottomSheetView)

        topConstraint = bottomSheetView.topAnchor.constraint(
            equalTo: containerView.topAnchor,
            constant: containerView.frame.maxY
        )

        NSLayoutConstraint.activate([
            topConstraint,
            bottomSheetView.bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor),
            bottomSheetView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomSheetView.heightAnchor.constraint(greaterThanOrEqualToConstant: compactModel.height)
        ])

        bottomSheetView.addGestureRecognizer(panGesture)

        springAnimator.addAnimation { [weak self] position in
            self?.topConstraint.constant = position.y
        }

        containerView.layoutIfNeeded()
    }

    func addModel(_ model: BottomSheetModel?, for state: BottomSheetState) {
        models[state] = model
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

    func transition(to state: BottomSheetState?) {
        guard let state = state else {
            delegate?.bottomSheetViewPresenter(self, didTransitionTo: nil)
            return
        }

        let containerHeight = containerView?.frame.height ?? 0

        if let model = models[state] {
            self.state = state
            animate(to: CGPoint(x: 0, y: containerHeight - model.height))
        } else if let model = models[self.state] {
            animate(to: CGPoint(x: 0, y: containerHeight - model.height))
        }

        delegate?.bottomSheetViewPresenter(self, didTransitionTo: state)
    }

    // MARK: - Private methods

    @objc private func handlePan(panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .began:
            springAnimator.pauseAnimation()
        case .ended, .cancelled, .failed:
            guard let model = models[state] else { return }
            let location = CGPoint(x: 0, y: topConstraint.constant)
            let state = model.stateMap.state(for: location)
            transition(to: state)
        default:
            break
        }

        let translation = panGesture.translation(in: containerView)
        topConstraint.constant += translation.y
        panGesture.setTranslation(.zero, in: containerView)
    }
}
