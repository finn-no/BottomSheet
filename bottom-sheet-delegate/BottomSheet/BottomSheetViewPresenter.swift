//
//  Copyright © FINN AS. All rights reserved.
//

import UIKit

protocol BottomSheetViewPresenterDelegate: AnyObject {
    func bottomSheetViewPresenter(_: BottomSheetViewPresenter, didTransitionTo height: BottomSheetHeight?)
}

final class BottomSheetViewPresenter {
    private static let handleHeight: CGFloat = 20

    weak var delegate: BottomSheetViewPresenterDelegate?

    // MARK: - Private properties

    private var currentHeight: BottomSheetHeight
    private let heights: [CGFloat]
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

    // MARK: - Init

    init(heights: [CGFloat]) {
        self.heights = heights.sorted()
        self.currentHeight = heights.first ?? .bottomSheetAutomatic
    }

    convenience init<T: RawRepresentable>(heights: [T]) where T.RawValue == CGFloat {
        self.init(heights: heights.map { $0.rawValue })
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

        let height = currentHeight.value(for: bottomSheetView, targetSize: containerView.frame.size)

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
        transition(to: currentHeight)
    }

    private func transition(to height: BottomSheetHeight?) {
        guard let bottomSheetView = bottomSheetView, let containerView = containerView else {
            return
        }

        guard let height = height else {
            delegate?.bottomSheetViewPresenter(self, didTransitionTo: nil)
            return
        }

        let containerHeight = containerView.frame.height
        currentHeight = height.value(for: bottomSheetView, targetSize: containerView.frame.size)
        animate(to: CGPoint(x: 0, y: containerHeight - currentHeight))

        delegate?.bottomSheetViewPresenter(self, didTransitionTo: currentHeight)
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
            let height = heights.bottomSheetHeight(for: location, in: containerView.frame.size)
            transition(to: height)
        default:
            break
        }

        let translation = panGesture.translation(in: containerView)
        topConstraint.constant += translation.y
        panGesture.setTranslation(.zero, in: containerView)
    }


}

private extension Array where Element == BottomSheetHeight {
    func bottomSheetHeight(for location: CGPoint, in targetSize: CGSize) -> BottomSheetHeight? {
        let value: (Element) -> CGFloat = { abs(targetSize.height - $0 - location.y) }
        return self.min(by: { value($0) < value($1) })
    }
}

private extension BottomSheetHeight {
    func value(for view: UIView, targetSize: CGSize) -> CGFloat {
        guard self == BottomSheetHeight.bottomSheetAutomatic else {
            return self
        }

        let size = view.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )

        return size.height
    }
}
