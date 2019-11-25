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
    static func createTranslationTargets(
        for targetOffsets: [CGFloat],
        at currentTargetIndex: Int,
        in superview: UIView,
        isDismissible: Bool
    ) -> [TranslationTarget] {
        guard !targetOffsets.isEmpty else { return [] }

        let minOffset = targetOffsets.last ?? 0
        let maxOffset = targetOffsets.first ?? 0
        let maxThreshold: CGFloat = 75

        // Thresholds is how long you need to translate from one translation target to another
        // If the BottomSheetView is dismissible we want the user to translate a certain amount before transitioning to the dismiss translation target
        // If not, make it stop at the smallest target height by setting the first threshold to zero.
        let lowestThreshold = isDismissible ? min((abs(superview.frame.height - maxOffset) * 0.25), maxThreshold) : 0
        // We add a zero threshold at the end to make the BottomSheetView stop at its biggest height.
        let highestThreshold: CGFloat = 0
        // Calculate all the offsets in between
        let thresholds = [lowestThreshold] + targetOffsets.mapPar { (first, second) -> CGFloat in
            min((abs(second - first) * 0.25), maxThreshold)
        } + [highestThreshold]

        // Calculate lower bounds
        let lowerOffsets = targetOffsets[currentTargetIndex...]
        let lowerThresholds = thresholds[(currentTargetIndex + 1)...]
        let lowerBounds = zip(lowerOffsets, lowerThresholds).map(-)

        // Calculate upper bounds
        let upperOffsets = targetOffsets[...currentTargetIndex]
        let upperThresholds = thresholds[...currentTargetIndex]
        let upperBounds = zip(upperOffsets, upperThresholds).map(+)

        let bounds = upperBounds + lowerBounds

        // Model used to control offsets bigger than or equal to maxOffset
        let bottomModel = LimitTarget(
            targetOffset: isDismissible ? superview.frame.height : maxOffset,
            bound: bounds.first ?? maxOffset,
            behavior: isDismissible ? .linear : .stop,
            isDismissible: isDismissible,
            compare: >=
        )

        var upperBound = bounds.first ?? 0
        var models: [TranslationTarget] = [bottomModel]

        for (targetOffset, lowerBound) in zip(targetOffsets, bounds.dropFirst()) {
            let model = RangeTarget(
                targetOffset: targetOffset,
                range: lowerBound ..< upperBound,
                isDismissible: false
            )

            models.append(model)
            upperBound = lowerBound
        }

        // Model used to control offsets smaller than  minOffset
        let topModel = LimitTarget(
            targetOffset: minOffset,
            bound: minOffset,
            behavior: .rubberBand(radius: min(minOffset * 0.25, maxThreshold)),
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
