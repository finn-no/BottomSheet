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

    public var isDimViewHidden: Bool {
        get { dimView.isHidden }
        set { dimView.isHidden = newValue }
    }

    // MARK: - Private properties

    private let preferredHeights: [CGFloat]
    private var topConstraint: NSLayoutConstraint!
    private var currentTargetOffset: CGFloat = 0
    private var targetOffsets = [CGFloat]()
    private weak var presentedView: UIView?
    private weak var containerView: UIView?
    private lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panGesture:)))
    private lazy var springAnimator = SpringAnimator(dampingRatio: 0.8, frequencyResponse: 0.4)

    private lazy var dimView: UIView = {
        let view = UIView(frame: .zero)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        view.isHidden = true
        view.alpha = 0
        return view
    }()

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

        containerView.addSubview(dimView)
        containerView.addSubview(bottomSheetView)
        dimView.frame = containerView.bounds

        topConstraint = bottomSheetView.topAnchor.constraint(
            equalTo: containerView.topAnchor,
            constant: containerView.frame.height
        )

        var constraints: [NSLayoutConstraint] = [
            topConstraint,
            bottomSheetView.bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor),
            bottomSheetView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ]

        updateTargetOffsets()

        if let maxOffset = targetOffsets.last {
            let minHeight = containerView.frame.height - maxOffset
            constraints.append(presentedView.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight))

            springAnimator.addAnimation { [weak self] position in
                self?.updateDimViewAlpha(for: position.y)
            }
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
        updateTargetOffsets()
        show()
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

    private func updateDimViewAlpha(for offset: CGFloat) {
        if let maxOffset = targetOffsets.last {
            dimView.alpha = min(1, maxOffset / offset)
        }
    }

    // MARK: - UIPanGestureRecognizer

    @objc private func handlePan(panGesture: UIPanGestureRecognizer) {
        let state = translationState(for: panGesture)

        switch panGesture.state {
        case .began:
            springAnimator.pauseAnimation()
        case .ended, .cancelled, .failed:
            animate(to: state.targetOffset)

            if state.isDismissible {
                delegate?.bottomSheetViewPresenterDidReachDismissArea(self)
            }
        default:
            break
        }

        topConstraint.constant = state.nextOffset
        updateDimViewAlpha(for: state.nextOffset)
        panGesture.setTranslation(.zero, in: containerView)
    }

    // MARK: - Offset calculation

    private func translationState(for panGesture: UIPanGestureRecognizer) -> TranslationState {
        let currentArea = currentTargetOffset - .translationThreshold ... currentTargetOffset + .translationThreshold
        let currentConstant = topConstraint.constant
        let translation = panGesture.translation(in: containerView)
        let dragConstant = topConstraint.constant + translation.y

        if currentArea.contains(dragConstant) {
            return TranslationState(nextOffset: dragConstant, targetOffset: currentTargetOffset, isDismissible: false)
        } else if dragConstant < currentTargetOffset {
            let targetOffset = targetOffsets.first(where: { $0 < dragConstant })
            return TranslationState(
                nextOffset: targetOffset == nil ? currentConstant : dragConstant,
                targetOffset: targetOffset ?? currentTargetOffset,
                isDismissible: false
            )
        } else {
            let targetOffset = targetOffsets.first(where: { $0 > dragConstant })
            return TranslationState(
                nextOffset: dragConstant,
                targetOffset: targetOffset ?? currentTargetOffset,
                isDismissible: targetOffset == nil
            )
        }
    }

    private func updateTargetOffsets() {
        targetOffsets = preferredHeights.compactMap(offset(from:)).sorted()
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

        let targetHeight = makeTargetHeight()
        let minOffset: CGFloat = .translationThreshold

        return max(containerView.frame.height - max(targetHeight, minOffset), minOffset)
    }
}

// MARK: - Private types

private struct TranslationState {
    let nextOffset: CGFloat
    let targetOffset: CGFloat
    let isDismissible: Bool
}
