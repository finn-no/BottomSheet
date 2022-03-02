//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit
import BottomSheet

final class DemoViewController: UIViewController {
    private lazy var bottomSheetTransitioningDelegate = BottomSheetTransitioningDelegate(
        contentHeights: [.bottomSheetAutomatic, UIScreen.main.bounds.size.height - 200],
        presentationDelegate: self
    )

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    // MARK: - Setup

    private func setup() {
        view.backgroundColor = .white

        let stackView = UIStackView(arrangedSubviews: [
            createButton(title: "Navigation View Controller", selector: #selector(presentNavigationViewController)),
            createButton(title: "View Controller", selector: #selector(presentViewController)),
            createButton(title: "View", selector: #selector(presentView)),
            createButton(title: "Automatic dismiss after 0.05s", selector: #selector(presentAutomaticDismiss)),
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func createButton(title: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }

    // MARK: - Presentation logic

    @objc private func presentNavigationViewController() {
        let viewController = ViewController(withNavigationButton: true, contentHeight: 400)
        viewController.title = "Step 1"

        let navigationController = BottomSheetNavigationController(rootViewController: viewController)
        navigationController.navigationBar.isTranslucent = false

        present(navigationController, animated: true)
    }

    @objc private func presentAutomaticDismiss() {
        let viewController = ViewController(withNavigationButton: true, contentHeight: 400)
        viewController.title = "Step 1"

        let navigationController = BottomSheetNavigationController(rootViewController: viewController)
        navigationController.navigationBar.isTranslucent = false

        present(navigationController, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: { [weak navigationController] in
            navigationController?.dismiss(animated: true)
        })
    }

    // MARK: - Presentation logic

    @objc private func presentViewController() {
        let viewController = ViewController(withNavigationButton: false, text: "UIViewController", contentHeight: 400)
        viewController.transitioningDelegate = bottomSheetTransitioningDelegate
        viewController.modalPresentationStyle = .custom
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

// MARK: - BottomSheetViewDismissalDelegate

extension DemoViewController: BottomSheetPresentationControllerDelegate {
    func bottomSheetPresentationController(
        _ controller: UIPresentationController,
        shouldDismissBy action: BottomSheetView.DismissAction
    ) -> Bool {
        return true
    }

    func bottomSheetPresentationController(
        _ controller: UIPresentationController,
        didCancelDismissBy action: BottomSheetView.DismissAction
    ) {
        print("Did cancel dismiss by \(action)")
    }

    func bottomSheetPresentationController(
        _ controller: UIPresentationController,
        willDismissBy action: BottomSheetView.DismissAction?
    ) {
        print("Will dismiss dismiss by \(String(describing: action))")
    }

    func bottomSheetPresentationController(
        _ controller: UIPresentationController,
        didDismissBy action: BottomSheetView.DismissAction?
    ) {
        print("Did dismiss dismiss by \(String(describing: action))")
    }
}

// MARK: - Private extensions

private extension UIView {
    static func makeView(withTitle title: String? = nil) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hue: 0.5, saturation: 0.3, brightness: 0.6, alpha: 1.0)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.textAlignment = .center
        label.textColor = .white
        view.addSubview(label)

        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = .white
        borderView.alpha = 0.4
        view.addSubview(borderView)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            borderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 2),
            borderView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }
}

private final class ViewController: UIViewController {
    private let withNavigationButton: Bool
    private let contentHeight: CGFloat
    private let text: String?

    init(withNavigationButton: Bool, text: String? = nil, contentHeight: CGFloat) {
        self.withNavigationButton = withNavigationButton
        self.text = text
        self.contentHeight = contentHeight
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let contentView = UIView.makeView(withTitle: text)
        view.backgroundColor = contentView.backgroundColor
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.heightAnchor.constraint(equalToConstant: contentHeight),
        ])

        preferredContentSize.height = contentHeight

        if withNavigationButton {
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            button.setTitle("Next", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
            view.addSubview(button)

            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
        }
    }

    @objc private func handleButtonTap() {
        let viewController = ViewController(withNavigationButton: false, contentHeight: contentHeight - 100)
        viewController.title = "Step 2"
        navigationController?.pushViewController(viewController, animated: true)
    }
}
