//
//  Copyright © 2018 FINN.no. All rights reserved.
//

import UIKit

public final class BottomSheetView: UIView {
    public static let handleHeight: CGFloat = 20
    public static let cornerRadius: CGFloat = 16

    // MARK: - Private properties

    private var models: [BottomSheetState: BottomSheetModel] = [:]
    private var state: BottomSheetState = .compact
    private var containerView: UIView?
    private var contentView: UIView?
    private var contentViewConstraints = [NSLayoutConstraint]()
    private var topConstraint: NSLayoutConstraint!

    private lazy var handleView: HandleView = {
        let handle = HandleView(height: BottomSheetView.handleHeight)
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

    // MARK: - Init

    public convenience init(contentView: UIView) {
        self.init(frame: .zero)
        self.contentView = contentView
        addContentView(contentView)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Overrides

    public override func layoutSubviews() {
        super.layoutSubviews()
        // Make shadow to be on top
        let rect = CGRect(x: 0, y: 0, width: bounds.width, height: BottomSheetView.handleHeight)
        layer.shadowPath = UIBezierPath(rect: rect).cgPath
    }

    // MARK: - Content view

    func addModel(_ model: BottomSheetModel?, for state: BottomSheetState) {
        models[state] = model
    }

    public func setContentView(_ newContentView: UIView) {
        removeContentView()
        addContentView(newContentView)
        contentView = newContentView
    }

    private func removeContentView() {
        NSLayoutConstraint.deactivate(contentViewConstraints)
        removeConstraints(contentViewConstraints)
        contentView?.removeFromSuperview()
    }

    private func addContentView(_ contentView: UIView) {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(contentView, belowSubview: handleView)

        contentViewConstraints = [
            contentView.topAnchor.constraint(equalTo: handleView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(contentViewConstraints)
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .white

        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = .zero
        layer.shadowRadius = 3
        layer.rasterizationScale = UIScreen.main.scale
        layer.cornerRadius = BottomSheetView.cornerRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        addSubview(handleView)

        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: topAnchor),
            handleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            handleView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

// MARK: - Private methods
private extension BottomSheetView {
    func transition(to state: BottomSheetState?) {
        guard let state = state else {
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
