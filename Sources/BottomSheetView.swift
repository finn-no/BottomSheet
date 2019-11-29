//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

// MARK: - Public extensions

extension CGFloat {
    public static let bottomSheetAutomatic: CGFloat = -123456789
}

// MARK: - Delegate

public protocol BottomSheetViewDelegate: AnyObject {
    func bottomSheetViewDidReachDismissArea(_ view: BottomSheetView)
}

// MARK: - View

public final class BottomSheetView: UIView {
    public weak var delegate: BottomSheetViewDelegate?

    public var isDimViewHidden: Bool {
        get { dimView.isHidden }
        set { dimView.isHidden = newValue }
    }

    // MARK: - Private properties

    private let isDismissable: Bool
    private let contentView: UIView
    private var topConstraint: NSLayoutConstraint!
    private let targetHeights: [CGFloat]
    private var targetOffsets = [CGFloat]()
    private var currentTargetOffsetIndex: Int = 0

    private var initialOffset: CGFloat?
    private var translationTargets = [TranslationTarget]()

    private lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panGesture:)))
    private lazy var springAnimator = SpringAnimator(dampingRatio: 0.8, frequencyResponse: 0.4)

    private lazy var handleView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .handle
        view.layer.cornerRadius = 2
        return view
    }()

    private lazy var dimView: UIView = {
        let view = UIView(frame: .zero)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        view.isHidden = true
        view.alpha = 0
        return view
    }()

    // MARK: - Init

    public init(contentView: UIView, targetHeights: [CGFloat], isDismissible: Bool = false) {
        self.contentView = contentView
        self.targetHeights = targetHeights.isEmpty ? [.bottomSheetAutomatic] : targetHeights
        self.isDismissable = isDismissible
        super.init(frame: .zero)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: - Overrides

    public override func layoutSubviews() {
        super.layoutSubviews()
        // Make shadow to be on top
        let rect = CGRect(x: 0, y: 0, width: bounds.width, height: 30)
        layer.shadowPath = UIBezierPath(rect: rect).cgPath
    }

    // MARK: - Public API

    /// Presents bottom sheet view from the bottom of the given container view.
    ///
    /// - Parameters:
    ///   - view: the container for the bottom sheet view
    ///   - completion: a closure to be executed when the animation ends
    public func present(in superview: UIView, targetIndex: Int = 0, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        guard self.superview != superview else { return }

        superview.addSubview(dimView)
        superview.addSubview(self)

        translatesAutoresizingMaskIntoConstraints = false
        dimView.frame = superview.bounds

        let startOffset = BottomSheetCalculator.offset(
            for: contentView,
            in: superview,
            height: targetHeights[targetIndex]
        )

        if animated {
            topConstraint = topAnchor.constraint(equalTo: superview.topAnchor, constant: superview.frame.height)
        } else {
            dimView.alpha = 1.0
            topConstraint = topAnchor.constraint(equalTo: superview.topAnchor, constant: startOffset)
        }

        springAnimator.addAnimation { [weak self] position in
            self?.topConstraint.constant = position.y
            self?.updateDimViewAlpha(for: position.y)
        }

        springAnimator.addCompletion { didComplete in completion?(didComplete) }

        NSLayoutConstraint.activate([
            topConstraint,
            bottomAnchor.constraint(greaterThanOrEqualTo: superview.bottomAnchor),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor)
        ])

        superview.layoutIfNeeded()
        addGestureRecognizer(panGesture)

        updateTargetOffsets()
        transition(to: targetIndex)
        createTranslationTargets()
    }

    /// Animates bottom sheet view out of the screen bounds and removes it from the superview on completion.
    ///
    /// - Parameters:
    ///   - completion: a closure to be executed when the animation ends
    public func dismiss(completion: ((Bool) -> Void)? = nil) {
        springAnimator.addCompletion { [weak self] didComplete in
            if didComplete {
                self?.dimView.removeFromSuperview()
                self?.removeFromSuperview()
            }

            completion?(didComplete)
        }

        animate(to: superview?.frame.height ?? 0)
    }

    /// Recalculates target offsets and animates to the minimum one.
    /// Call this method e.g. when orientation change is detected.
    public func reset() {
        updateTargetOffsets()
        createTranslationTargets()
        animate(to: targetOffsets[currentTargetOffsetIndex])
    }

    /// Animates bottom sheet view to the given height.
    ///
    /// - Parameters:
    ///   - index: the index of the target height
    public func transition(to index: Int) {
        guard targetHeights.indices.contains(index) else {
            assertionFailure("Provided index is out of bounds of the array with target heights.")
            return
        }

        guard let superview = superview else {
            return
        }

        let offset = BottomSheetCalculator.offset(for: contentView, in: superview, height: targetHeights[index])
        animate(to: offset)
    }

    // MARK: - Setup

    private func setup() {
        clipsToBounds = true
        backgroundColor = contentView.backgroundColor

        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = .zero
        layer.shadowRadius = 3
        layer.rasterizationScale = UIScreen.main.scale
        layer.cornerRadius = 16
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        addSubview(contentView)
        addSubview(handleView)

        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            handleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 25),
            handleView.heightAnchor.constraint(equalToConstant: 4),

            contentView.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 8),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }

    // MARK: - Animations

    private func animate(to offset: CGFloat, with initialVelocity: CGPoint = .zero) {
        if let index = targetOffsets.firstIndex(of: offset) {
            currentTargetOffsetIndex = index
        }

        springAnimator.fromPosition = CGPoint(x: 0, y: topConstraint.constant)
        springAnimator.toPosition = CGPoint(x: 0, y: offset)
        springAnimator.initialVelocity = initialVelocity
        springAnimator.startAnimation()
    }

    private func updateDimViewAlpha(for offset: CGFloat) {
        if let superview = superview, let maxOffset = targetOffsets.max() {
            dimView.alpha = min(1, (superview.frame.height - offset) / (superview.frame.height - maxOffset))
        }
    }

    // MARK: - UIPanGestureRecognizer

    @objc private func handlePan(panGesture: UIPanGestureRecognizer) {
        initialOffset = initialOffset ?? topConstraint.constant
        let translation = panGesture.translation(in: superview)
        let location = initialOffset! + translation.y

        guard let translationTarget = translationTargets.first(where: { $0.contains(offset: location) }) else {
            return
        }

        switch panGesture.state {
        case .began:
            springAnimator.pauseAnimation()

        case .changed:
            updateDimViewAlpha(for: location)
            topConstraint.constant = translationTarget.nextOffset(for: location)

        case .ended, .cancelled, .failed:
            initialOffset = nil

            if translationTarget.isDismissible {
                delegate?.bottomSheetViewDidReachDismissArea(self)
            } else {
                animate(to: translationTarget.targetOffset)
                createTranslationTargets()
            }

        default:
            break
        }
    }

    // MARK: - Offset calculation

    private func updateTargetOffsets() {
        guard let superview = superview else { return }

        targetOffsets = targetHeights.map {
            BottomSheetCalculator.offset(for: contentView, in: superview, height: $0)
        }.sorted(by: >)
    }

    private func createTranslationTargets() {
        guard let superview = superview else { return }

        translationTargets = BottomSheetCalculator.createTranslationTargets(
            for: targetOffsets,
            at: currentTargetOffsetIndex,
            in: superview,
            isDismissible: isDismissable
        )
    }
}

// MARK: - Private extensions

private extension UIColor {
    class var handle: UIColor {
        let defaultColor = UIColor(red: 195/255, green: 204/255, blue: 217/255, alpha: 1)

        if #available(iOS 13.0, *) {
            #if swift(>=5.1)
            return UIColor { traitCollection -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(red: 67/255, green: 67/255, blue: 89/255, alpha: 1)
                default:
                    return defaultColor
                }
            }
            #endif
        }

        return defaultColor
    }
}
