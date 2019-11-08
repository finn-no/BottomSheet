//
//  ViewController.swift
//  bottom-sheet-delegate
//
//  Created by Granheim Brustad , Henrik on 01/11/2019.
//  Copyright © 2019 Henrik Brustad. All rights reserved.
//

import UIKit

extension BottomSheetConfiguration {
    static var `default`: BottomSheetConfiguration {
        let screenSize = UIScreen.main.bounds.size
        return BottomSheetConfiguration(
            compactModel: BottomSheetModel(
                height: 510,
                stateMap: BottomSheetStateMap(
                    areas: [
                        BottomSheetStateArea(
                            bounds: CGRect(minX: 0, minY: 64,
                                           maxX: screenSize.width, maxY: screenSize.height - 510 - 75),
                            state: .expanded),
                        BottomSheetStateArea(
                            bounds: CGRect(minX: 0, minY: screenSize.height - 510 - 75,
                                           maxX: screenSize.width, maxY: screenSize.height - 510 + 75),
                            state: .compact)
                    ]
                )
            ),
            expandedModel: BottomSheetModel(
                height: screenSize.height - 64,
                stateMap: BottomSheetStateMap(
                    areas: [
                        BottomSheetStateArea(
                            bounds: CGRect(minX: 0, minY: -100,
                                           maxX: screenSize.width, maxY: 139),
                            state: .expanded),
                        BottomSheetStateArea(
                            bounds: CGRect(minX: 0, minY: 139,
                                           maxX: screenSize.width, maxY: screenSize.height - 510 + 75),
                            state: .compact)
                    ]
                )
            )
        )
    }
}

final class ViewController: UIViewController {

    private lazy var bottomSheetTransitioningDelegate = BottomSheetTransitioningDelegate(
        configuration: .default
    )

    private lazy var viewController: UIViewController = {
        let viewController = UIViewController(nibName: nil, bundle: nil)
        viewController.view.backgroundColor = UIColor(hue: 0.5, saturation: 0.3, brightness: 0.6, alpha: 1.0)
        viewController.transitioningDelegate = bottomSheetTransitioningDelegate
        viewController.modalPresentationStyle = .custom
        return viewController
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.backgroundColor = .white
        present(viewController, animated: true)
    }
}

