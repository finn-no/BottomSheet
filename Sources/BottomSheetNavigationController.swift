//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

open class BottomSheetNavigationController: UINavigationController {
    private var bottomSheetTransitioningDelegate: BottomSheetTransitioningDelegate?

    // MARK: - Init

    public init(rootViewController: UIViewController, useSafeAreaInsets: Bool = false) {
        super.init(rootViewController: rootViewController)
        bottomSheetTransitioningDelegate = BottomSheetTransitioningDelegate(
            contentHeights: [systemLayoutSizeFittingHeight(for: rootViewController)],
            useSafeAreaInsets: useSafeAreaInsets
        )
        transitioningDelegate = bottomSheetTransitioningDelegate
        modalPresentationStyle = .custom
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = false
        delegate = self
    }

    // MARK: - Navigation

    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if let view = viewController.view {
            view.removeFromSuperview()
            viewController.view = WrapperView(contentView: view)
        }

        super.pushViewController(viewController, animated: animated)
    }

    // MARK: - Public

    public func systemLayoutSizeFittingHeight(for viewController: UIViewController) -> CGFloat {
        let navigationBarHeight = navigationBar.isTranslucent ? 0 : navigationBar.frame.size.height
        let size = viewController.view.systemLayoutSizeFitting(
            view.frame.size,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return size.height + navigationBarHeight
    }

    public func reload(with height: CGFloat) {
        bottomSheetTransitioningDelegate?.reload(with: [height])
    }
}

// MARK: - UINavigationControllerDelegate

extension BottomSheetNavigationController: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController, animated: Bool
    ) {
        let height = systemLayoutSizeFittingHeight(for: viewController)
        reload(with: height)
    }
}

// MARK: - Private types

private final class WrapperView: UIView {
    private let contentView: UIView

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        return contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
    }

    private func setup() {
        backgroundColor = contentView.backgroundColor
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}
