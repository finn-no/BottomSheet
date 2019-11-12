//
//  Copyright © 2018 FINN.no. All rights reserved.
//

import UIKit

final class BottomSheetView: UIView {
    // MARK: - Private properties

    private let contentView: UIView

    private lazy var handleView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 2
        return view
    }()

    // MARK: - Init

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: - Overrides

    override func layoutSubviews() {
        super.layoutSubviews()
        // Make shadow to be on top
        let rect = CGRect(x: 0, y: 0, width: bounds.width, height: 30)
        layer.shadowPath = UIBezierPath(rect: rect).cgPath
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
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
