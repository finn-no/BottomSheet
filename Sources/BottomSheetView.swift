//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

// MARK: - Public extensions

extension CGFloat {
    public static let bottomSheetAutomatic: CGFloat = -123456789
}

extension Array where Element == CGFloat {
    public static var bottomSheetDefault: [CGFloat] {
        let screenSize = UIScreen.main.bounds.size

        if screenSize.height <= 568 {
            return [510]
        } else if screenSize.height >= 812 {
            return [570, screenSize.height - 64]
        } else {
            return [510, screenSize.height - 64]
        }
    }
}

// MARK: - Delegate

public protocol BottomSheetViewDismissalDelegate: AnyObject {
    func bottomSheetView(_ view: BottomSheetView, willDismissBy action: BottomSheetView.DismissAction)
}

public protocol BottomSheetViewAnimationDelegate: AnyObject {
    func bottomSheetView(_ view: BottomSheetView, didAnimateToPosition position: CGPoint)
    func bottomSheetView(_ view: BottomSheetView, didCompleteAnimation complete: Bool)
}

// MARK: - View

public final class BottomSheetView: UIView {
    public enum HandleBackground {
        case color(UIColor)
        case visualEffect(UIVisualEffect)

        var view: UIView {
            switch self {
            case .color(let value):
                let view = UIView()
                view.backgroundColor = value
                return view
            case .visualEffect(let value):
                return UIVisualEffectView(effect: value)
            }
        }
    }

    public enum DismissAction {
        case drag(velocity: CGPoint)
        case tap
    }

    public weak var dismissalDelegate: BottomSheetViewDismissalDelegate?
    public weak var animationDelegate: BottomSheetViewAnimationDelegate?
    public private(set) var contentHeights: [CGFloat]
    public private(set) var currentTargetOffsetIndex: Int = 0

    public var isDimViewHidden: Bool {
        get { dimView.isHidden }
        set { dimView.isHidden = newValue }
    }

    public let draggableHeight: CGFloat?

    var dimViewBackgroundColor: UIColor? {
        dimView.backgroundColor
    }

    // MARK: - Private properties

    private let useSafeAreaInsets: Bool
    private let stretchOnResize: Bool
    private let contentView: UIView
    private let handleBackground: HandleBackground
    private var topConstraint: NSLayoutConstraint!
    private var targetOffsets = [CGFloat]()
    private var initialOffset: CGFloat?
    private var translationTargets = [TranslationTarget]()
    private lazy var springAnimator = SpringAnimator(dampingRatio: 0.8, frequencyResponse: 0.4)
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(tapGesture:)))

    private lazy var panGesture: UIPanGestureRecognizer = {
        let gestureRecognizer = PanGestureRecognizer(target: self, action: #selector(handlePan(panGesture:)))
        gestureRecognizer.draggableHeight = draggableHeight
        return gestureRecognizer
    }()

    private var bottomInset: CGFloat {
        return useSafeAreaInsets ? .safeAreaBottomInset : 0
    }

    private lazy var handleView: HandleView = {
        let view = HandleView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    private lazy var dimView: UIView = {
        let view = UIView(frame: .zero)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        view.addGestureRecognizer(tapGesture)
        view.isHidden = true
        view.alpha = 0
        return view
    }()

    private lazy var contentViewHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)

    // MARK: - Init

    public init(
        contentView: UIView,
        contentHeights: [CGFloat],
        handleBackground: HandleBackground = .color(.clear),
        draggableHeight: CGFloat? = nil,
        useSafeAreaInsets: Bool = false,
        stretchOnResize: Bool = false,
        dismissalDelegate: BottomSheetViewDismissalDelegate? = nil,
        animationDelegate: BottomSheetViewAnimationDelegate? = nil
    ) {
        self.contentView = contentView
        self.handleBackground = handleBackground
        self.draggableHeight = draggableHeight
        self.contentHeights = contentHeights.isEmpty ? [.bottomSheetAutomatic] : contentHeights
        self.useSafeAreaInsets = useSafeAreaInsets
        self.stretchOnResize = stretchOnResize
        self.dismissalDelegate = dismissalDelegate
        self.animationDelegate = animationDelegate
        super.init(frame: .zero)
        setup()
        accessibilityViewIsModal = true
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
        guard
            self.superview != superview,
            let height = contentHeights[safe: targetIndex]
        else { return }

        superview.addSubview(dimView)
        superview.addSubview(self)

        translatesAutoresizingMaskIntoConstraints = false
        dimView.frame = superview.bounds

        let startOffset = BottomSheetCalculator.offset(
            for: contentView,
            in: superview,
            height: height,
            useSafeAreaInsets: useSafeAreaInsets
        )

        if animated {
            topConstraint = topAnchor.constraint(equalTo: superview.topAnchor, constant: superview.frame.height)
        } else {
            dimView.alpha = 1.0
            topConstraint = topAnchor.constraint(equalTo: superview.topAnchor, constant: startOffset)
        }

        springAnimator.addAnimation { [weak self] position in
            guard let self = self else { return }
            self.updateDimViewAlpha(for: position.y)
            self.topConstraint.constant = position.y
            self.animationDelegate?.bottomSheetView(self, didAnimateToPosition: position)
        }

        springAnimator.addCompletion { [weak self] didComplete in
            guard let self = self else { return }
            completion?(didComplete)
            self.animationDelegate?.bottomSheetView(self, didCompleteAnimation: didComplete)
        }

        NSLayoutConstraint.activate([
            topConstraint,
            bottomAnchor.constraint(greaterThanOrEqualTo: superview.bottomAnchor),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            contentViewHeightConstraint
        ])

        updateTargetOffsets()
        addGestureRecognizer(panGesture)

        transition(to: targetIndex)
        createTranslationTargets()
    }

    /// Animates bottom sheet view out of the screen bounds and removes it from the superview on completion.
    ///
    /// - Parameters:
    ///   - completion: a closure to be executed when the animation ends
    public func dismiss(velocity: CGPoint = .zero, completion: ((Bool) -> Void)? = nil) {
        springAnimator.addCompletion { [weak self] didComplete in
            if didComplete {
                self?.contentView.constraints.forEach { constraint in
                    self?.contentView.removeConstraint(constraint)
                }
                self?.contentView.removeFromSuperview()
                self?.dimView.removeFromSuperview()
                self?.removeFromSuperview()
                self?.springAnimator.invalidate()
            }

            completion?(didComplete)
        }

        animate(to: superview?.frame.height ?? 0, with: velocity)
    }

    /// Recalculates target offsets and animates to the minimum one.
    /// Call this method e.g. when orientation change is detected.
    public func reset() {
        updateTargetOffsets()
        createTranslationTargets()

        if let targetOffset = targetOffsets[safe: currentTargetOffsetIndex] {
            animate(to: targetOffset)
        }
    }

    public func reload(with contentHeights: [CGFloat], targetIndex: Int?) {
        self.contentHeights = contentHeights
        if let targetIndex = targetIndex {
            currentTargetOffsetIndex = targetIndex
        }
        reset()
    }

    /// Animates bottom sheet view to the given height.
    ///
    /// - Parameters:
    ///   - index: the index of the target height
    public func transition(to index: Int) {
        guard let height = contentHeights[safe: index] else {
            return
        }

        guard let superview = superview else {
            return
        }

        let offset = BottomSheetCalculator.offset(
            for: contentView,
            in: superview,
            height: height,
            useSafeAreaInsets: useSafeAreaInsets
        )

        animate(to: offset)
    }

    // MARK: - Setup

    private func setup() {
        clipsToBounds = true
        backgroundColor = contentView.backgroundColor ?? .bgPrimary

        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = .zero
        layer.shadowRadius = 3
        layer.rasterizationScale = UIScreen.main.scale
        layer.cornerRadius = 16
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let handleBackgroundView = handleBackground.view
        handleBackgroundView.layer.cornerRadius = layer.cornerRadius
        handleBackgroundView.layer.maskedCorners = layer.maskedCorners
        handleBackgroundView.clipsToBounds = true

        addSubview(contentView)
        addSubview(handleBackgroundView)
        addSubview(handleView)

        handleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        var constraints = [
            handleBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            handleBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            handleBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            handleBackgroundView.heightAnchor.constraint(equalToConstant: .handleHeight),

            handleView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            handleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 25),
            handleView.heightAnchor.constraint(equalToConstant: 4),

            contentView.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 8),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ]

        if stretchOnResize {
            constraints.append(contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomInset))
        } else {
            constraints.append(contentView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -bottomInset))
        }

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Internal methods

    func hideDimView() {
        dimView.removeFromSuperview()
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
        if offset <= topConstraint.constant && dimView.alpha == 1 {
            return
        }

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

            let velocity = translationTarget.translateVelocity(
                panGesture.velocity(in: superview),
                for: location
            )

            func animateToTranslationTarget() {
                animate(to: translationTarget.targetOffset, with: velocity)
                createTranslationTargets()
            }

            // if it's the bottom limit target
            if translationTarget.isBottomTarget {
                if let dismissalDelegate = dismissalDelegate {
                    dismissalDelegate.bottomSheetView(self, willDismissBy: .drag(velocity: velocity))
                } else {
                    animateToTranslationTarget()
                }
            } else {
                animateToTranslationTarget()
            }

        default:
            break
        }
    }

    // MARK: - UITapGestureRecognizer

    @objc private func handleTap(tapGesture: UITapGestureRecognizer) {
        dismissalDelegate?.bottomSheetView(self, willDismissBy: .tap)
    }

    // MARK: - Offset calculation

    private func updateTargetOffsets() {
        guard let superview = superview else { return }

        contentViewHeightConstraint.constant = 0

        targetOffsets = contentHeights.map {
            BottomSheetCalculator.offset(for: contentView, in: superview, height: $0, useSafeAreaInsets: useSafeAreaInsets)
        }.sorted(by: >)

        if let maxOffset = targetOffsets.max() {
            let contentViewHeight = superview.frame.size.height - maxOffset - .handleHeight - bottomInset
            contentViewHeightConstraint.constant = contentViewHeight
        }

        superview.layoutIfNeeded()
    }

    private func createTranslationTargets() {
        guard let superview = superview else { return }

        translationTargets = BottomSheetCalculator.createTranslationTargets(
            for: targetOffsets,
            at: currentTargetOffsetIndex,
            in: superview,
            targetMaxHeight: dismissalDelegate != nil
        )
    }
}

// MARK: - Private types

private class PanGestureRecognizer: UIPanGestureRecognizer {
    var draggableHeight: CGFloat?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let firstTouch = touches.first, let view = view, let draggableHeight = draggableHeight else {
            return super.touchesBegan(touches, with: event)
        }

        let height = CGFloat.handleHeight + draggableHeight
        let touchPoint = firstTouch.location(in: view)
        let draggableRect = CGRect(x: 0, y: 0, width: view.frame.width, height: height)

        if draggableRect.contains(touchPoint) {
            super.touchesBegan(touches, with: event)
        }
    }
}

// MARK: - HandleViewDelegate

extension BottomSheetView: HandleViewDelegate {
    func didPerformAccessibilityActivate(_ view: HandleView) -> Bool {
        dismissalDelegate?.bottomSheetView(self, willDismissBy: .tap)
        return true
    }
}

// MARK: - Internal extensions

extension UIColor {
    class var handle: UIColor {
        return dynamicColorIfAvailable(
            defaultColor: UIColor(red: 195/255, green: 204/255, blue: 217/255, alpha: 1),
            darkModeColor: UIColor(red: 67/255, green: 67/255, blue: 89/255, alpha: 1)
        )
    }

    class var bgPrimary: UIColor {
        return dynamicColorIfAvailable(
            defaultColor: .white,
            darkModeColor: UIColor(red: 27/255, green: 27/255, blue: 36/255, alpha: 1)
        )
    }

    class func dynamicColorIfAvailable(defaultColor: UIColor, darkModeColor: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            #if swift(>=5.1)
            return UIColor { traitCollection -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return darkModeColor
                default:
                    return defaultColor
                }
            }
            #endif
        }

        return defaultColor
    }
}
