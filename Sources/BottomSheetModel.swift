//
//  Copyright © 2019 FINN.no. All rights reserved.
//

import CoreGraphics

/// Model defining a certain area of a BottomSheetView.
///
protocol BottomSheetModel {

    /// An offset which a BottomSheetView can transition to
    ///
    var targetOffset: CGFloat { get }

    /// Flag specifying whether a BottomSheetView should be dismissed.
    /// This should only be used when presented by a presentation controller
    ///
    var isDismissible: Bool { get }

    /// BottomSheetView will find the model which contains the current translation offset
    /// and transition to its target offset when it's gesture ends.
    ///
    /// - Parameters:
    ///   - offset: some offset. E.g. a pan gesture's translation, a table view's contentOffset.
    ///
    /// Return true if a BottomSheetView should transition to this target offset.
    ///
    func contains(offset: CGFloat) -> Bool

    /// This method is called when a BottomSheetView's pan gesture changes.
    ///
    /// - Parameters:
    ///   - offset: some offset. E.g. a pan gesture's translation, a table view's contentOffset.
    ///
    /// BottomSheetView calls this method to set the constant of it's constraint
    /// Use this method to alter the panning movement of a BottomSheetView. E.g. make it bounce, or stick to a value.
    ///
    func nextOffset(for offset: CGFloat) -> CGFloat
}

/// RangeModel has an upper and a lower bound defining a range around the target offset
///
struct RangeModel: BottomSheetModel {
    let targetOffset: CGFloat
    let range: Range<CGFloat>
    let isDismissible: Bool

    func contains(offset: CGFloat) -> Bool {
        range.contains(offset)
    }

    func nextOffset(for offset: CGFloat) -> CGFloat {
        offset
    }
}

/// LimitModel will compare the offset against it's target offset
///
/// A lower limit model will stop a BottomSheetView to translate below it's lowest target offset
///
///     let lowerLimit = LimitModel(
///         targetOffset: offset,
///         isDismissable: false,
///         compare: <
///     )
///
struct LimitModel: BottomSheetModel {
    let targetOffset: CGFloat
    let isDismissible: Bool
    let compare: (CGFloat, CGFloat) -> Bool

    func contains(offset: CGFloat) -> Bool {
        compare(offset, targetOffset)
    }

    func nextOffset(for offset: CGFloat) -> CGFloat {
        targetOffset
    }
}
