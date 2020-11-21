//
//  Copyright © FINN.no AS. All rights reserved.
//

import UIKit

protocol HandleViewDelegate: AnyObject {
    func didPerformAccessibilityActivate(_ view: HandleView) -> Bool
}

class HandleView: UIView {

    weak var delegate: HandleViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .handle
        layer.cornerRadius = 2

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "Lukk"
    }

    override func accessibilityActivate() -> Bool {
        delegate?.didPerformAccessibilityActivate(self) ?? false
    }
}
