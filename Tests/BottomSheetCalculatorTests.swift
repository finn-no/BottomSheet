//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import XCTest
@testable import BottomSheet

final class BottomSheetCalculatorTests: XCTestCase {
    private let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
    private let superview = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 400))

    func testOffsetWithAutomaticheight() {
        // 400 - 200 - 20 (handle height)
        XCTAssertEqual(BottomSheetCalculator.offset(for: view, in: superview, height: .bottomSheetAutomatic), 180)
    }

    func testOffsetWithHeightSmallerThanSuperviewHeight() {
        XCTAssertEqual(BottomSheetCalculator.offset(for: view, in: superview, height: 300), 100) // 400 - 300
    }

    func testOffsetWithHeightBiggerThanSuperviewHeight() {
        XCTAssertEqual(BottomSheetCalculator.offset(for: view, in: superview, height: 500), 20) // Handle height
    }

    func testOffsetWithZeroHeight() {
        XCTAssertEqual(BottomSheetCalculator.offset(for: view, in: superview, height: 0), 400) // Superview height
    }

    func testLayoutWithEmptyOffsets() {
        XCTAssertTrue(BottomSheetCalculator.createTranslationTargets(for: [], at: 0, in: superview, isDismissible: false).isEmpty)
    }

    func testLayoutModelsWithSingleOffset() {
        let models = BottomSheetCalculator.createTranslationTargets(for: [500], at: 0, in: superview, isDismissible: false)

        XCTAssertEqual(models.count, 3)
        XCTAssertTrue(models[0] is LimitTarget)
        XCTAssertTrue(models[1] is RangeTarget)
        XCTAssertTrue(models[2] is LimitTarget)
    }

    func testLayoutModelsWithMultipleOffsets() {
        let models = BottomSheetCalculator.createTranslationTargets(for: [700, 300, 100], at: 0, in: superview, isDismissible: false)

        XCTAssertEqual(models.count, 5)
        XCTAssertTrue(models.first is LimitTarget)
        XCTAssertTrue(models.last is LimitTarget)
    }

    func testLayoutModelsWhenContainingOffset() {
        let models = BottomSheetCalculator.createTranslationTargets(for: [700, 300, 100], at: 0, in: superview, isDismissible: false)

        XCTAssertTrue(models[0].contains(offset: 800))
        XCTAssertTrue(models[1].contains(offset: 690))
        XCTAssertTrue(models[2].contains(offset: 300))
        XCTAssertTrue(models[3].contains(offset: 100))
        XCTAssertTrue(models[4].contains(offset: 20))

    }

    func testLayoutModelsWhenNotContainingOffset() {
        let models = BottomSheetCalculator.createTranslationTargets(for: [700, 300, 100], at: 0, in: superview, isDismissible: false)
        XCTAssertFalse(models[0].contains(offset: 600))
        XCTAssertFalse(models[1].contains(offset: 300))
        XCTAssertFalse(models[2].contains(offset: 100))
        XCTAssertFalse(models[3].contains(offset: 20))
        XCTAssertFalse(models[4].contains(offset: 100))
    }

    func testLayoutThresholds() {
        let models = BottomSheetCalculator.createTranslationTargets(for: [700, 600, 400], at: 1, in: superview, isDismissible: false)

        guard let firstModel = models[1] as? RangeTarget else {
            return
        }

        XCTAssertEqual(firstModel.range.lowerBound, 600 + 25)
        XCTAssertEqual(firstModel.range.upperBound, 700 - 0)

        guard let secondModel = models[2] as? RangeTarget else {
            return
        }

        XCTAssertEqual(secondModel.range.lowerBound, 600 - 50)
        XCTAssertEqual(secondModel.range.upperBound, 600 + 25)

        guard let thirdModel = models[3] as? RangeTarget else {
            return
        }

        XCTAssertEqual(thirdModel.range.lowerBound, 400 - 0)
        XCTAssertEqual(thirdModel.range.upperBound, 600 - 50)
    }
}
