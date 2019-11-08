//
//  CGRect.swift
//  bottom-sheet-delegate
//
//  Created by Granheim Brustad , Henrik on 08/11/2019.
//  Copyright © 2019 Henrik Brustad. All rights reserved.
//

import CoreGraphics

extension CGRect {
    init(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
        let origin = CGPoint(
            x: minX,
            y: minY
        )

        let size = CGSize(
            width: maxX - minX,
            height: maxY - minY
        )

        self.init(
            origin: origin,
            size: size
        )
    }
}
