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
    private var models = [BottomSheetModel]()
    private var initialOffset: CGFloat = 0

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
    public func present(in superview: UIView, targetIndex: Int = 0, completion: ((Bool) -> Void)? = nil) {
        guard self.superview != superview else { return }

        superview.addSubview(dimView)
        superview.addSubview(self)

        translatesAutoresizingMaskIntoConstraints = false
        dimView.frame = superview.bounds
        topConstraint = topAnchor.constraint(equalTo: superview.topAnchor, constant: superview.frame.height)

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

        currentTargetOffsetIndex = targetIndex
        updateTargetOffsets()
        transition(to: targetIndex)
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
        transition(to: 0)
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
        // Adds one to compansate for limit model at beginning
        guard models.indices.contains(index + 1) else {
            return
        }

        animate(to: models[index + 1].targetOffset)
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

    private func animate(to offset: CGFloat) {
        if let index = targetOffsets.firstIndex(of: offset) {
            currentTargetOffsetIndex = index
        }

        springAnimator.fromPosition = CGPoint(x: 0, y: topConstraint.constant)
        springAnimator.toPosition = CGPoint(x: 0, y: offset)
        springAnimator.initialVelocity = .zero
        springAnimator.startAnimation()
    }

    private func updateDimViewAlpha(for offset: CGFloat) {
        if let superview = superview, let mainOffset = targetOffsets.first(where: { $0 < super.frame.height }) {
            dimView.alpha = min(1, (superview.frame.height - offset) / (superview.frame.height - mainOffset))
        }
    }

    // MARK: - UIPanGestureRecognizer

    @objc private func handlePan(panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .began:
            springAnimator.pauseAnimation()
            initialOffset = topConstraint.constant

        case .changed:
            let translation = panGesture.translation(in: superview)
            let location = initialOffset + translation.y

            guard let model = models[location] else { return }

            updateDimViewAlpha(for: location)
            topConstraint.constant = model.nextOffset(for: location)

        case .ended, .cancelled, .failed:
            let translation = panGesture.translation(in: superview)
            let location = initialOffset + translation.y

            guard let model = models[location] else { return }

            if model.isDismissible {
                delegate?.bottomSheetViewDidReachDismissArea(self)
            } else {
                animate(to: model.targetOffset)
                updateTargetOffsets()
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
        }

        models = BottomSheetCalculator.createLayout(
            for: targetOffsets,
            at: currentTargetOffsetIndex,
            isDismissible: isDismissable
        )
    }
}

// MARK: - Private extensions

private extension Array where Element == BottomSheetModel {
    subscript(offset: CGFloat) -> BottomSheetModel? {
        first { model -> Bool in
            model.contains(offset: offset)
        }
    }
}

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
