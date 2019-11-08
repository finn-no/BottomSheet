//
//  BottomSheetPresentationController.swift
//  bottom-sheet-delegate
//
//  Created by Granheim Brustad , Henrik on 01/11/2019.
//  Copyright © 2019 Henrik Brustad. All rights reserved.
//

import UIKit

extension BottomSheetPresentationController {
    enum TransitionState {
        case presenting
        case dismissing
    }
}

class BottomSheetPresentationController: UIPresentationController {

    // MARK: - Internal properties

    var transitionState: TransitionState = .presenting

    // MARK: - Private properties

    private var models: [BottomSheetState: BottomSheetModel] = [:]
    private var state: BottomSheetState = .compact

    private var topConstraint: NSLayoutConstraint!

    private lazy var handle: BottomSheetHandle = {
        let handle = BottomSheetHandle(height: 20)
        handle.translatesAutoresizingMaskIntoConstraints = false
        return handle
    }()

    private lazy var backgroundView: UIView = {
        let view = UIView(frame: .zero)
//        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var panGesture = UIPanGestureRecognizer(
        target: self,
        action: #selector(handlePan(panGesture:))
    )

    private lazy var springAnimator = SpringAnimator(
        dampingRatio: 0.8,
        frequencyResponse: 0.4
    )

    // MARK: - Transition life cycle

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        guard let presentedView = presentedView else { return }
        guard let compactModel = models[.compact] else { return }

        presentedView.layer.cornerRadius = 16
        presentedView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        presentedView.layer.masksToBounds = true
        presentedView.translatesAutoresizingMaskIntoConstraints = false
        handle.backgroundColor = presentedView.backgroundColor

        topConstraint = presentedView.topAnchor.constraint(
            equalTo: containerView.topAnchor,
            constant: containerView.frame.maxY
        )

        containerView.addSubview(backgroundView)
        presentedView.addSubview(handle)
        containerView.addSubview(presentedView)

        NSLayoutConstraint.activate([
            topConstraint,
            presentedView.heightAnchor.constraint(greaterThanOrEqualToConstant: compactModel.height),
            presentedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            presentedView.bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor),
            presentedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            handle.leadingAnchor.constraint(equalTo: presentedView.leadingAnchor),
            handle.topAnchor.constraint(equalTo: presentedView.topAnchor),
            handle.trailingAnchor.constraint(equalTo: presentedView.trailingAnchor),

            backgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            backgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        presentedView.addGestureRecognizer(panGesture)

        springAnimator.addAnimation { [weak self] position in
            self?.topConstraint.constant = position.y
        }

        containerView.layoutIfNeeded()
    }

}

// MARK: - Internal methods
extension BottomSheetPresentationController {
    func addModel(_ model: BottomSheetModel?, for state: BottomSheetState) {
        models[state] = model
    }
}

// MARK: - UIViewControllerAnimatedTransitioning
extension BottomSheetPresentationController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        springAnimator.addCompletion { didComplete in
            transitionContext.completeTransition(didComplete)
        }

        switch transitionState {
        case .presenting:
            transition(to: state)
        case .dismissing:
            let point = CGPoint(
                x: 0,
                y: containerView?.frame.height ?? 0
            )

            animate(to: point)
        }
    }
}

// MARK: - UIViewControllerInteractiveTransitioning
extension BottomSheetPresentationController: UIViewControllerInteractiveTransitioning {
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        animateTransition(using: transitionContext)
    }
}

// MARK: - Private methods
private extension BottomSheetPresentationController {
    func transition(to state: BottomSheetState?) {
        guard let state = state else {
            presentedViewController.dismiss(animated: true)
            return
        }

        let containerHeight = containerView?.frame.height ?? 0

        if let model = models[state] {
            self.state = state
            animate(to: CGPoint(x: 0, y: containerHeight - model.height))
        } else if let model = models[self.state] {
            animate(to: CGPoint(x: 0, y: containerHeight - model.height))
        }
    }

    func animate(to position: CGPoint) {
        springAnimator.fromPosition = CGPoint(x: 0, y: topConstraint.constant)
        springAnimator.toPosition = position
        springAnimator.initialVelocity = .zero
        springAnimator.startAnimation()
    }

    @objc func handlePan(panGesture: UIPanGestureRecognizer) {
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

// MARK: - Bottom Sheet Handle
private class BottomSheetHandle: UIView {

    private lazy var handle: UIView = {
        let view = UIView(frame: .zero)
        view.layer.cornerRadius = 2
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(height: CGFloat) {
        super.init(frame: .zero)

        addSubview(handle)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
            handle.widthAnchor.constraint(equalToConstant: 25),
            handle.heightAnchor.constraint(equalToConstant: 4),
            handle.centerXAnchor.constraint(equalTo: centerXAnchor),
            handle.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}
