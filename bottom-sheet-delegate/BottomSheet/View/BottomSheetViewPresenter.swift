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
    private var state: BottomSheetState = .compact
    private var topConstraint: NSLayoutConstraint!
    private var containerView: UIView?

    private lazy var handle: HandleView = {
        let handle = HandleView(height: 20)
        handle.translatesAutoresizingMaskIntoConstraints = false
        return handle
    }()

    private lazy var panGesture = UIPanGestureRecognizer(
        target: self,
        action: #selector(handlePan(panGesture:))
    )

    private lazy var springAnimator = SpringAnimator(
        dampingRatio: 0.8,
        frequencyResponse: 0.4
    )

    // MARK: - Presentation

    func present(_ presentedView: UIView, in containerView: UIView) {
        guard let compactModel = models[.compact] else { return }

        self.containerView = containerView

        presentedView.layer.cornerRadius = 16
        presentedView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        presentedView.layer.masksToBounds = true
        presentedView.translatesAutoresizingMaskIntoConstraints = false

        handle.backgroundColor = presentedView.backgroundColor

        containerView.addSubview(handle)
        containerView.addSubview(presentedView)

        topConstraint = presentedView.topAnchor.constraint(
            equalTo: handle.bottomAnchor,
            constant: containerView.frame.maxY
        )

        NSLayoutConstraint.activate([
            handle.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            handle.topAnchor.constraint(equalTo: containerView.topAnchor),
            handle.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            topConstraint,
            presentedView.bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor),
            presentedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            presentedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            presentedView.heightAnchor.constraint(greaterThanOrEqualToConstant: compactModel.height)
        ])

        presentedView.addGestureRecognizer(panGesture)

        springAnimator.addAnimation { [weak self] position in
            self?.topConstraint.constant = position.y
        }

        containerView.layoutIfNeeded()
    }

    // MARK: - Internal methods

    func addModel(_ model: BottomSheetModel?, for state: BottomSheetState) {
        models[state] = model
    }

    // MARK: - Private methods

    private func transition(to state: BottomSheetState?) {
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

    private func animate(to position: CGPoint) {
        springAnimator.fromPosition = CGPoint(x: 0, y: topConstraint.constant)
        springAnimator.toPosition = position
        springAnimator.initialVelocity = .zero
        springAnimator.startAnimation()
    }

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
