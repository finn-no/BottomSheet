//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

struct BottomSheetCalculator {
    private static let handleHeight: CGFloat = 20

    /// Calculates offset for the given content view within its superview, taking preferred height into account.
    ///
    /// - Parameters:
    ///   - contentView: the content view of the bottom sheet
    ///   - superview: the bottom sheet container view
    ///   - height: preferred height for the content view
    static func offset(for contentView: UIView, in superview: UIView, height: CGFloat) -> CGFloat {
        var targetHeight = contentHeight(for: contentView, in: superview, height: height)

        if height == .bottomSheetAutomatic {
            targetHeight += BottomSheetCalculator.handleHeight
        }

        return max(superview.frame.height - targetHeight, BottomSheetCalculator.handleHeight)
    }

    static func contentHeight(for contentView: UIView, in superview: UIView, height: CGFloat) -> CGFloat {
        let contentHeight: CGFloat

        if height == .bottomSheetAutomatic {
            let size = contentView.systemLayoutSizeFitting(
                superview.frame.size,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            contentHeight = size.height
        } else {
            contentHeight = height
        }

        return min(contentHeight, superview.frame.height - 64 - BottomSheetCalculator.handleHeight)
    }

    /// Creates the translation targets of a BottomSheetView based on an array of target offsets and the current target offset
    ///
    /// - Parameters:
    ///   - targetOffsets: array containing the different target offsets a BottomSheetView can transition between
    ///   - currentTargetIndex: index of the current target offset of the BottomSheetView
    ///   - superview: the bottom sheet container view
    ///   - isDismissable: flag specifying whether the last translation target should dismiss the BottomSheetView
    static func createTranslationTargets(
        for targetOffsets: [CGFloat],
        at currentTargetIndex: Int,
        in superview: UIView,
        isDismissible: Bool
    ) -> [TranslationTarget] {
        guard !targetOffsets.isEmpty else { return [] }

        let minOffset = targetOffsets.last ?? 0
        let maxOffset = targetOffsets.first ?? 0

        // Thresholds is how long you need to translate from one translation target to another
        // Calculates the threshold between two offsets
        func threshold(_ offsetA: CGFloat, _ offsetB: CGFloat) -> CGFloat {
            let maxThreshold: CGFloat = 75
            return min(abs(offsetB - offsetA) * 0.25, maxThreshold)
        }
        // If the BottomSheetView is dismissible we want the user to translate a certain amount before transitioning to the dismiss translation target
        // If not, make it stop at the smallest target height by setting the first threshold to zero.
        let lowestThreshold = isDismissible ? threshold(superview.frame.height, maxOffset) : 0
        // We add a zero threshold at the end to make the BottomSheetView stop at its biggest height.
        let highestThreshold: CGFloat = 0
        // Calculate all the offsets in between
        let thresholds = [lowestThreshold] + zip(targetOffsets.dropFirst(), targetOffsets).map { threshold($0, $1) } + [highestThreshold]

        // Calculate lower bounds
        let lowerOffsets = targetOffsets[currentTargetIndex...]
        let lowerThresholds = thresholds[(currentTargetIndex + 1)...]
        let lowerBounds = zip(lowerOffsets, lowerThresholds).map(-)

        // Calculate upper bounds
        let upperOffsets = targetOffsets[...currentTargetIndex]
        let upperThresholds = thresholds[...currentTargetIndex]
        let upperBounds = zip(upperOffsets, upperThresholds).map(+)

        let bounds = upperBounds + lowerBounds

        // Target used to control offsets bigger than or equal to maxOffset
        let bottomTarget = LimitTarget(
            targetOffset: isDismissible ? superview.frame.height : maxOffset,
            bound: bounds.first ?? maxOffset,
            behavior: isDismissible ? .linear : .rubberBand(radius: threshold(0, maxOffset)),
            isDismissible: isDismissible,
            compare: >=
        )

        var upperBound = bounds.first ?? 0
        var targets: [TranslationTarget] = [bottomTarget]

        for (targetOffset, lowerBound) in zip(targetOffsets, bounds.dropFirst()) {
            let target = RangeTarget(
                targetOffset: targetOffset,
                range: lowerBound ..< upperBound,
                isDismissible: false
            )

            targets.append(target)
            upperBound = lowerBound
        }

        // Target used to control offsets smaller than minOffset
        let topTarget = LimitTarget(
            targetOffset: minOffset,
            bound: minOffset,
            behavior: .rubberBand(radius: threshold(0, minOffset)),
            isDismissible: false,
            compare: <
        )

        targets.append(topTarget)

        return targets
    }
}
