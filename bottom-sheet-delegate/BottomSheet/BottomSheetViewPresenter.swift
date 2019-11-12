//
//  Copyright © FINN AS. All rights reserved.
//

import UIKit

protocol BottomSheetViewPresenterDelegate: AnyObject {
    func bottomSheetViewPresenter(_: BottomSheetViewPresenter, didTransitionToHeight height: CGFloat)
}

final class BottomSheetViewPresenter {
    weak var delegate: BottomSheetViewPresenterDelegate?

    // MARK: - Private properties

    private let states: [State]
    private weak var presentedView: UIView?
    private weak var containerView: UIView?
    private var topConstraint: NSLayoutConstraint!

    private lazy var panGesture = UIPanGestureRecognizer(
        target: self,
        action: #selector(handlePan(panGesture:))
    )

    private lazy var springAnimator = SpringAnimator(
        dampingRatio: 0.8,
        frequencyResponse: 0.4
    )

    // MARK: - Init

    init(preferredHeights: [CGFloat]) {
        self.states = preferredHeights.map({ State(preferredHeight: $0) })
    }

    convenience init<T: RawRepresentable>(preferredHeights: [T]) where T.RawValue == CGFloat {
        self.init(preferredHeights: preferredHeights.map { $0.rawValue })
    }

    // MARK: - Internal methods

    func add(_ presentedView: UIView, to containerView: UIView) {
        self.presentedView = presentedView
        self.containerView = containerView

        let bottomSheetView = BottomSheetView(contentView: presentedView)
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.addGestureRecognizer(panGesture)
        containerView.addSubview(bottomSheetView)

        topConstraint = bottomSheetView.topAnchor.constraint(
            equalTo: containerView.topAnchor,
            constant: containerView.frame.maxY
        )

        var constraints: [NSLayoutConstraint] = [
            topConstraint,
            bottomSheetView.bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor),
            bottomSheetView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ]

        if let minHeight = states.minHeight(for: presentedView, in: containerView) {
            constraints.append(presentedView.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight))
        }

        NSLayoutConstraint.activate(constraints)

        springAnimator.addAnimation { [weak self] position in
            self?.topConstraint.constant = position.y
        }

        containerView.layoutIfNeeded()
    }

    func show() {
        guard let presentedView = presentedView, let containerView = containerView else { return }
        guard let height = states.first?.preferredHeight(for: presentedView, in: containerView) else { return }
        transition(to: height, presentedView: presentedView, containerView: containerView)
    }

    func hide() {
        guard let containerView = containerView else { return }
        animate(to: containerView.frame.height)
    }

    func transition<T: RawRepresentable>(to height: T) where T.RawValue == CGFloat {
        guard let presentedView = presentedView, let containerView = containerView else { return }
        transition(to: height.rawValue, presentedView: presentedView, containerView: containerView)
    }

    func addAnimationCompletion(_ completion: @escaping (Bool) -> Void) {
        springAnimator.addCompletion { didComplete in
            completion(didComplete)
        }
    }

    // MARK: - Private methods

    private func transition(to height: CGFloat, presentedView: UIView, containerView: UIView) {
        animate(to: containerView.frame.height - height)
    }

    private func animate(to constant: CGFloat) {
        springAnimator.fromPosition = CGPoint(x: 0, y: topConstraint.constant)
        springAnimator.toPosition = CGPoint(x: 0, y: constant)
        springAnimator.initialVelocity = .zero
        springAnimator.startAnimation()
    }

    @objc private func handlePan(panGesture: UIPanGestureRecognizer) {
        guard let presentedView = presentedView, let containerView = containerView else { return }

        switch panGesture.state {
        case .began:
            springAnimator.pauseAnimation()
        case .ended, .cancelled, .failed:
            let location = CGPoint(x: 0, y: topConstraint.constant)

            if let height = states.height(for: location, view: presentedView, in: containerView) {
                if height == .bottomSheetDismissed {
                    delegate?.bottomSheetViewPresenter(self, didTransitionToHeight: height)
                } else {
                    transition(to: height, presentedView: presentedView, containerView: containerView)
                }
            }
        default:
            break
        }

        let translation = panGesture.translation(in: containerView)
        topConstraint.constant += translation.y
        panGesture.setTranslation(.zero, in: containerView)
    }
}

private struct State: Equatable {
    private let preferredHeight: CGFloat

    init(preferredHeight: CGFloat) {
        self.preferredHeight = preferredHeight
    }

    func preferredHeight(for view: UIView, in containerView: UIView) -> CGFloat {
        guard preferredHeight == .bottomSheetAutomatic else {
            return preferredHeight
        }

        let size = view.systemLayoutSizeFitting(
            containerView.frame.size,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return size.height
    }
}

private extension Array where Element == State {
    func height(for location: CGPoint, view: UIView, in containerView: UIView) -> CGFloat? {
        let yPosition: (CGFloat) -> CGFloat = { abs(containerView.frame.height - $0 - location.y) }
        return preferredHeights(for: view, in: containerView).min(by: { yPosition($0) < yPosition($1) })
    }

    func minHeight(for view: UIView, in containerView: UIView) -> CGFloat? {
        preferredHeights(for: view, in: containerView).min()
    }

    private func preferredHeights(for view: UIView, in containerView: UIView) -> [CGFloat] {
        self.map({ $0.preferredHeight(for: view, in: containerView) })
    }
}

extension CGFloat {
    static let bottomSheetAutomatic: CGFloat = -123456789
    static let bottomSheetDismissed: CGFloat = 0
}
