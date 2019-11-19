//
//  ViewController.swift
//  bottom-sheet-delegate
//
//  Created by Granheim Brustad , Henrik on 01/11/2019.
//  Copyright © 2019 Henrik Brustad. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    private lazy var bottomSheetTransitioningDelegate = BottomSheetTransitioningDelegate(
        preferredHeights: [.bottomSheetAutomatic, UIScreen.main.bounds.size.height - 200]
    )

    private lazy var viewController: UIViewController = {
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

        return viewController
    }()

    private lazy var bottomSheetView = BottomSheetView(
        contentView: UIView.makeView(withTitle: "UIView"),
        preferredHeights: [100, 500]
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        view.backgroundColor = .white

        let buttonA = UIButton(type: .system)
        buttonA.setTitle("View Controller", for: .normal)
        buttonA.titleLabel?.font = .systemFont(ofSize: 18)
        buttonA.addTarget(self, action: #selector(presentViewController), for: .touchUpInside)

        let buttonB = UIButton(type: .system)
        buttonB.setTitle("View", for: .normal)
        buttonB.titleLabel?.font = .systemFont(ofSize: 18)
        buttonB.addTarget(self, action: #selector(presentView), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [buttonA, buttonB])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func presentViewController() {
        present(viewController, animated: true)
    }

    @objc private func presentView() {
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
