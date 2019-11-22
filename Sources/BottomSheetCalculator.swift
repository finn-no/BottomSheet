//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

struct BottomSheetCalculator {
    /// Calculates offset for the given content view within its superview, taking preferred height into account.
    ///
    /// - Parameters:
    ///   - contentView: the content view of the bottom sheet
    ///   - superview: the bottom sheet container view
    ///   - height: preferred height for the content view
    static func offset(for contentView: UIView, in superview: UIView, height: CGFloat) -> CGFloat {
        let handleHeight: CGFloat = 20

        func makeTargetHeight() -> CGFloat {
            if height == .bottomSheetAutomatic {
                let size = contentView.systemLayoutSizeFitting(
                    superview.frame.size,
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                )
                return size.height + handleHeight
            } else {
                return height
            }
        }

        return max(superview.frame.height - makeTargetHeight(), handleHeight)
    }

    /// Creates the layout of the BottomSheetView based on the target offsets and the current target offset
    ///
    /// - Parameters:
    ///   - targetOffsets: array containing the different target offsets a BottomSheetView can transition between
    ///   - currentTargetIndex: index of the current target offset of the BottomSheetView
    ///   - isDismissable: flag specifying whether the last two offsets should dismiss the BottomSheetView
    static func createLayout(for targetOffsets: [CGFloat], at currentTargetIndex: Int, isDismissible: Bool) -> [BottomSheetModel] {
        guard !targetOffsets.isEmpty else { return [] }

        let minOffset = targetOffsets.last ?? 0
        let maxOffset = targetOffsets.first ?? 0
        let maxThreshold: CGFloat = 75

        // [0, thresholds, 0]
        // Add 0s to array to limit translation above and below edge offsets
        let thresholds = [0] + targetOffsets.mapPar { (first, second) -> CGFloat in
            min((abs(second - first) * 0.25), maxThreshold)
        } + [0]

        guard thresholds.count == targetOffsets.count + 1 else {
            return []
        }

        // Calculate lower bounds
        let lowerOffsets = targetOffsets[currentTargetIndex...]
        let lowerThresholds = thresholds[(currentTargetIndex + 1)...]
        let lowerBounds = zip(lowerOffsets, lowerThresholds).map { (offset, threshold) -> CGFloat in
            offset - threshold
        }

        // Calculate upper bounds
        let upperOffsets = targetOffsets[...currentTargetIndex]
        let upperThresholds = thresholds[...currentTargetIndex]
        let upperBounds = zip(upperOffsets, upperThresholds).map { (offset, threshold) -> CGFloat in
            offset + threshold
        }

        let bounds = upperBounds.dropFirst() + lowerBounds
        var upperBound = upperBounds.first ?? 0

        // Model used to control offsets bigger than or equal to maxOffset
        let bottomModel = LimitModel(
            targetOffset: maxOffset,
            isDismissible: isDismissible,
            compare: >=
        )

        var models: [BottomSheetModel] = [bottomModel]

        for (index, lowerBound) in bounds.enumerated() {
            let model = RangeModel(
                targetOffset: targetOffsets[index],
                range: lowerBound ..< upperBound,
                isDismissible: isDismissible && index == 0
            )

            models.append(model)
            upperBound = lowerBound
        }

        // Model used to control offsets smaller than  minOffset
        let topModel = LimitModel(
            targetOffset: minOffset,
            isDismissible: false,
            compare: <
        )

        models.append(topModel)

        return models
    }
}

// MARK: - Helper types

private extension Sequence {

    /// Iterate through array two elements at a time
    ///
    func mapPar<T>(_ transform: (Element, Element) -> T) -> [T] {
        var iterator = makeIterator()
        var transformed = [T]()

        guard var first = iterator.next() else {
            return []
        }

        while let second = iterator.next() {
            transformed.append(transform(first, second))
            first = second
        }

        return transformed
    }
}
