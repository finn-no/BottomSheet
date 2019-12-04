//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit
import BottomSheet

final class DemoViewController: UIViewController {
    private lazy var bottomSheetTransitioningDelegate = BottomSheetTransitioningDelegate(
        contentHeights: [.bottomSheetAutomatic, UIScreen.main.bounds.size.height - 200]
    )

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    // MARK: - Setup

    private func setup() {
        view.backgroundColor = .white

        let buttonA = UIButton(type: .system)
        buttonA.setTitle("Navigation View Controller", for: .normal)
        buttonA.titleLabel?.font = .systemFont(ofSize: 18)
        buttonA.addTarget(self, action: #selector(presentNavigationViewController), for: .touchUpInside)

        let buttonB = UIButton(type: .system)
        buttonB.setTitle("View Controller", for: .normal)
        buttonB.titleLabel?.font = .systemFont(ofSize: 18)
        buttonB.addTarget(self, action: #selector(presentViewController), for: .touchUpInside)

        let buttonC = UIButton(type: .system)
        buttonC.setTitle("View", for: .normal)
        buttonC.titleLabel?.font = .systemFont(ofSize: 18)
        buttonC.addTarget(self, action: #selector(presentView), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [buttonA, buttonB, buttonC])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Presentation logic

    @objc private func presentNavigationViewController() {
        let viewController = UIViewController()
        viewController.title = "My View Controller"

        let view = UIView.makeView(withTitle: "UIViewController in Navigation Controller")
        viewController.view.backgroundColor = view.backgroundColor
        viewController.view.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: viewController.view.topAnchor, constant: 16),
            view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.isTranslucent = false
        navigationController.transitioningDelegate = bottomSheetTransitioningDelegate
        navigationController.modalPresentationStyle = .custom

        present(navigationController, animated: true)
    }

    // MARK: - Presentation logic

    @objc private func presentViewController() {
        let viewController = UIViewController()
        viewController.transitioningDelegate = bottomSheetTransitioningDelegate
        viewController.modalPresentationStyle = .custom

        let view = UIView.makeView(withTitle: "UIViewController")
        viewController.view.backgroundColor = view.backgroundColor
        viewController.view.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            view.heightAnchor.constraint(equalToConstant: 400),
            view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])

        present(viewController, animated: true)
    }

    @objc private func presentView() {
        let bottomSheetView = BottomSheetView(
            contentView: UIView.makeView(withTitle: "UIView"),
            contentHeights: [100, 500]
        )
        bottomSheetView.present(in: view)
    }
}

// MARK: - Private extensions

private extension UIView {
    static func makeView(withTitle title: String) -> UIView {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.textAlignment = .center
        label.textColor = .white

        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hue: 0.5, saturation: 0.3, brightness: 0.6, alpha: 1.0)
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        return view
    }
}
