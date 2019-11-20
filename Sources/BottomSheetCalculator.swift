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

    /// Calculates bottom and top thresholds for the given target offsets.
    /// - Parameters:
    ///   - contentView: the content view of the bottom sheet
    ///   - superview: the bottom sheet container view
    ///   - height: preferred height for the content view
    static func thresholds(for targetOffsets: [CGFloat], in superview: UIView) -> [CGFloat] {
        guard !targetOffsets.isEmpty else { return [] }

        let maxThreshold: CGFloat = 75
        let targetOffsets = [0] + targetOffsets + [superview.frame.height]

        return zip(targetOffsets.dropFirst(), targetOffsets).map {
            min(abs(($0 - $1) * 0.25), maxThreshold)
        }
    }

    static func translationState(
        from source: CGFloat,
        to destination: CGFloat,
        targetOffsets: [CGFloat],
        thresholds: [CGFloat],
        currentTargetOffsetIndex: Int
    ) -> TranslationState? {
        guard currentTargetOffsetIndex >= 0 && currentTargetOffsetIndex < targetOffsets.count else { return nil }
        guard thresholds.count == targetOffsets.count + 1 else { return nil }

        let currentTargetOffset = targetOffsets[currentTargetOffsetIndex]
        let lowerBound = currentTargetOffset - thresholds[currentTargetOffsetIndex]
        let upperBound = currentTargetOffset + thresholds[currentTargetOffsetIndex + 1]
        let currentArea = lowerBound ... upperBound

        if currentArea.contains(destination) {
            // Within the area of the current target offset, allow dragging.
            return TranslationState(nextOffset: destination, targetOffset: currentTargetOffset, isDismissible: false)
        } else if destination < currentTargetOffset {
            let targetOffset = targetOffsets.first(where: { $0 < destination })
            // Above the area of the current target offset, allow dragging if the next target offset is found.
            return TranslationState(
                nextOffset: targetOffset == nil ? source : destination,
                targetOffset: targetOffset ?? currentTargetOffset,
                isDismissible: false
            )
        } else {
            let targetOffset = targetOffsets.first(where: { $0 > destination })
            // Below the area of the current target offset,
            // allow dragging and set as dismissable if the next target offset is not found.
            return TranslationState(
                nextOffset: destination,
                targetOffset: targetOffset ?? currentTargetOffset,
                isDismissible: targetOffset == nil
            )
        }
    }
}

// MARK: - Helper types

struct TranslationState {
    /// The offset to be set for the current pan gesture translation.
    let nextOffset: CGFloat
    /// The offset to be set when the pan gesture ended, cancelled or failed.
    let targetOffset: CGFloat
    /// A flag indicating whether the view is ready to be dismissed.
    let isDismissible: Bool
}
