//
//  Copyright © 2019 FINN.no. All rights reserved.
//

import CoreGraphics

/// Model defining a certain area of a BottomSheetView.
///
protocol TranslationTarget {

    /// An offset which a BottomSheetView can transition to
    var targetOffset: CGFloat { get }

    /// Flag specifying whether it is a bottom limit target.
    var isBottomTarget: Bool { get }

    /// BottomSheetView will find the model which contains the current translation offset
    /// and transition to its target offset when its gesture ends.
    ///
    /// - Parameters:
    ///   - offset: some offset. E.g. a pan gestures translation, a table views contentOffset.
    ///
    /// - Returns: true if a BottomSheetView should transition to this target offset.
    func contains(offset: CGFloat) -> Bool

    /// This method is called when a BottomSheetViews pan gesture changes.
    /// BottomSheetView calls this method to set the constant of its constraint
    /// Use this method to alter the panning movement of a BottomSheetView. E.g. give it a rubber band effect
    /// or make it stop at a certain offset
    ///
    /// - Parameters:
    ///   - offset: some offset. E.g. a pan gestures translation, a table views contentOffset.
    func nextOffset(for offset: CGFloat) -> CGFloat

    /// This method is called when a BottomSheetViews pan gesture ends.
    /// Use this method together with nextOffset(for:) to make a nice transition
    /// between panning and animation.
    ///
    /// - Parameters:
    ///   - velocity: the velocity of a pan gesture
    ///   - offset: some offset. E.g. a pan gestures translation, a table views contentOffset.
    ///
    /// - Returns: The initial velocity of the spring animator.
    func translateVelocity(_ velocity: CGPoint, for offset: CGFloat) -> CGPoint
}

/// Defines the behavior of the translation
enum TranslationBehavior {
    case linear
    case rubberBand(radius: CGFloat)
    case stop
}

/// RangeTarget has an upper and a lower bound defining a range around its target offset
struct RangeTarget: TranslationTarget {
    let targetOffset: CGFloat
    let range: Range<CGFloat>
    let isBottomTarget: Bool

    func contains(offset: CGFloat) -> Bool {
        range.contains(offset)
    }

    func nextOffset(for offset: CGFloat) -> CGFloat {
        offset
    }

    func translateVelocity(_ velocity: CGPoint, for offset: CGFloat) -> CGPoint {
        velocity
    }
}

/// LimitTarget will compare the offset against its bound
///
/// A lower limit model will stop a BottomSheetView translating below its lowest target offset
///
///     let lowerLimit = LimitModel(
///         targetOffset: offset,
///         bound: offset,
///         behavior: .stop,
///         isDismissable: false,
///         compare: <
///     )
///
struct LimitTarget: TranslationTarget {
    let targetOffset: CGFloat
    let bound: CGFloat
    let behavior: TranslationBehavior
    let isBottomTarget: Bool
    let compare: (CGFloat, CGFloat) -> Bool

    func contains(offset: CGFloat) -> Bool {
        compare(offset, bound)
    }

    func nextOffset(for offset: CGFloat) -> CGFloat {
        switch behavior {
        case .linear:
            return offset
        case .rubberBand(let radius):
            let distance = offset - bound
            let newOffset = radius * (1 - exp(-abs(distance) / radius))

            if distance < 0 {
                return bound - newOffset
            } else {
                return bound + newOffset
            }

        case .stop:
            return bound
        }
    }

    func translateVelocity(_ velocity: CGPoint, for offset: CGFloat) -> CGPoint {
        switch behavior {
        case .linear:
            return velocity
        case .rubberBand(let radius):
            let distance = offset - bound
            let constant = exp(-abs(distance) / radius)

            return CGPoint(
                x: velocity.x * constant,
                y: velocity.y * constant
            )
        case .stop:
            return .zero
        }
    }
}
