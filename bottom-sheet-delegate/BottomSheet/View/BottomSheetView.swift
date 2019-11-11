//
//  Copyright © 2018 FINN.no. All rights reserved.
//

import UIKit

public final class BottomSheetView: UIView {
    public static let handleHeight: CGFloat = 20
    public static let cornerRadius: CGFloat = 16

    // MARK: - Private properties

    private lazy var handleView: HandleView = {
        let handle = HandleView(height: BottomSheetView.handleHeight)
        handle.translatesAutoresizingMaskIntoConstraints = false
        return handle
    }()

    private var contentView: UIView?
    private var contentViewConstraints = [NSLayoutConstraint]()

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
