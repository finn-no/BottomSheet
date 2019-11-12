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

    private let config: BottomSheetConfiguration

    private lazy var presenter: BottomSheetViewPresenter = {
        let presenter = BottomSheetViewPresenter(config: config)
        presenter.delegate = self
        return presenter
    }()

    private lazy var backgroundView: UIView = {
        let view = UIView(frame: .zero)
//        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Init

    init(presentedViewController: UIViewController, presenting: UIViewController?, config: BottomSheetConfiguration) {
        self.config = config
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    // MARK: - Transition life cycle

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        guard let presentedView = presentedView else { return }

        containerView.addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            backgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        presenter.addPresentedView(presentedView, to: containerView)
    }
}

// MARK: - UIViewControllerAnimatedTransitioning
extension BottomSheetPresentationController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        presenter.addAnimationCompletion { didComplete in
            transitionContext.completeTransition(didComplete)
        }

        switch transitionState {
        case .presenting:
            presenter.present()
        case .dismissing:
            let point = CGPoint(
                x: 0,
                y: containerView?.frame.height ?? 0
            )

            presenter.animate(to: point)
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
extension BottomSheetPresentationController: BottomSheetViewPresenterDelegate {
    func bottomSheetViewPresenter(_: BottomSheetViewPresenter, didTransitionTo state: BottomSheetState?) {
        if state == nil {
            presentedViewController.dismiss(animated: true)
        }
    }
}
