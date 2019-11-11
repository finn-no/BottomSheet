//
//  Copyright © FINN AS. All rights reserved.
//

import UIKit

final class HandleView: UIView {
    private lazy var handle: UIView = {
        let view = UIView(frame: .zero)
        view.layer.cornerRadius = 2
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(height: CGFloat) {
        super.init(frame: .zero)

        addSubview(handle)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
            handle.widthAnchor.constraint(equalToConstant: 25),
            handle.heightAnchor.constraint(equalToConstant: 4),
            handle.centerXAnchor.constraint(equalTo: centerXAnchor),
            handle.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}
