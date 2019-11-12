//
//  Copyright © FINN AS. All rights reserved.
//

import UIKit

public protocol BottomSheetViewPresenterDelegate: AnyObject {
    func bottomSheetViewPresenterDidReachDismissArea(_ presenter: BottomSheetViewPresenter)
}

public final class BottomSheetViewPresenter {
    // MARK: - Public properties

    public weak var delegate: BottomSheetViewPresenterDelegate?

    // MARK: - Private properties

    private let preferredHeights: [CGFloat]
    private var topConstraint: NSLayoutConstraint!
    private var currentTargetOffset: CGFloat = 0
    private weak var presentedView: UIView?
    private weak var containerView: UIView?
    private lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panGesture:)))
    private lazy var springAnimator = SpringAnimator(dampingRatio: 0.8, frequencyResponse: 0.4)

    private var targetOffsets: [CGFloat] {
        preferredHeights.compactMap(offset(from:)).sorted()
    }

    // MARK: - Init

    public init(preferredHeights: [CGFloat]) {
        self.preferredHeights = preferredHeights
    }

    public convenience init<T: RawRepresentable>(preferredHeights: [T]) where T.RawValue == CGFloat {
        self.init(preferredHeights: preferredHeights.map { $0.rawValue })
    }

    // MARK: - API

    public func add(_ presentedView: UIView, to containerView: UIView) {
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

        if let maxOffset = targetOffsets.last {
            let minHeight = containerView.frame.height - maxOffset
            constraints.append(presentedView.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight))
        }

        NSLayoutConstraint.activate(constraints)

        springAnimator.addAnimation { [weak self] position in
            self?.topConstraint.constant = position.y
        }

        containerView.layoutIfNeeded()
    }

    public func show() {
        guard let maxOffset = targetOffsets.last else { return }
        animate(to: maxOffset)
    }

    public func hide() {
        animate(to: containerView?.frame.height ?? 0)
    }

    public func reset() {
        animate(to: currentTargetOffset)
    }

    public func transition<T: RawRepresentable>(to height: T) where T.RawValue == CGFloat {
        guard let offset = offset(from: height.rawValue) else { return }
        animate(to: offset)
    }

    func addAnimationCompletion(_ completion: @escaping (Bool) -> Void) {
        springAnimator.addCompletion { didComplete in
            completion(didComplete)
        }
    }

    // MARK: - Animations

    private func animate(to constant: CGFloat) {
        if targetOffsets.contains(constant) {
            currentTargetOffset = constant
        }

        springAnimator.fromPosition = CGPoint(x: 0, y: topConstraint.constant)
        springAnimator.toPosition = CGPoint(x: 0, y: constant)
        springAnimator.initialVelocity = .zero
        springAnimator.startAnimation()
    }

    // MARK: - UIPanGestureRecognizer

    @objc private func handlePan(panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .began:
            springAnimator.pauseAnimation()
        case .ended, .cancelled, .failed:
            if let offset = targetOffset(for: topConstraint.constant, currentTargetOffset: currentTargetOffset) {
                animate(to: offset)
            } else if let delegate = delegate {
                delegate.bottomSheetViewPresenterDidReachDismissArea(self)
            } else {
                animate(to: currentTargetOffset)
            }
        default:
            break
        }

        let translation = panGesture.translation(in: containerView)
        topConstraint.constant += translation.y
        panGesture.setTranslation(.zero, in: containerView)
    }

    // MARK: - Offset calculation

    private func targetOffset(for panOffset: CGFloat, currentTargetOffset: CGFloat) -> CGFloat? {
        let threshold: CGFloat = 75
        let previousArea = currentTargetOffset - threshold ... currentTargetOffset + threshold

        if previousArea.contains(panOffset) {
            return currentTargetOffset
        } else if panOffset < currentTargetOffset {
            return targetOffsets.first(where: { $0 < panOffset })
        } else {
            return targetOffsets.first(where: { $0 > panOffset })
        }
    }

    private func offset(from height: CGFloat) -> CGFloat? {
        guard let presentedView = presentedView, let containerView = containerView else { return nil }

        func makeTargetHeight() -> CGFloat {
            if height == .bottomSheetAutomatic {
                let size = presentedView.systemLayoutSizeFitting(
                    containerView.frame.size,
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                )

                return size.height
            } else {
                return height
            }
        }

        return containerView.frame.height - makeTargetHeight()
    }
}
