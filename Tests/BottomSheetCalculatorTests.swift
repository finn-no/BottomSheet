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

    func testThresholdsWithEmptyTargetOffsets() {
        XCTAssertTrue(BottomSheetCalculator.thresholds(for: [], in: superview).isEmpty)
    }

    func testThresholdsWithSingleTargetOffset() {
        XCTAssertEqual(BottomSheetCalculator.thresholds(for: [100], in: superview), [25, 75])
    }

    func testThresholdsWithMultipleTargetOffset() {
        XCTAssertEqual(BottomSheetCalculator.thresholds(for: [56, 200], in: superview), [14, 36, 50])
        XCTAssertEqual(BottomSheetCalculator.thresholds(for: [100, 250, 500], in: superview), [25.0, 37.5, 62.5, 25.0])
    }

    func testThresholdsWithBigDistanceBetweenTargetOffsets() {
        XCTAssertEqual(BottomSheetCalculator.thresholds(for: [100, 1000], in: superview), [25.0, 75.0, 75.0])
    }

    func testTranslationStateWithinCurrentArea() {
        let targetOffsets: [CGFloat] = [56, 200]
        let thresholds: [CGFloat] = [36, 36, 36]

        let state = BottomSheetCalculator.translationState(
            from: 60,
            to: 70,
            targetOffsets: targetOffsets,
            thresholds: thresholds,
            currentTargetOffsetIndex: 0
        )

        XCTAssertEqual(state?.nextOffset, 70)
        XCTAssertEqual(state?.targetOffset, 56)
        XCTAssertEqual(state?.isDismissible, false)
    }

    func testTranslationStateToAreaBelow() {
        let targetOffsets: [CGFloat] = [56, 200]
        let thresholds: [CGFloat] = [36, 36, 36]

        let state = BottomSheetCalculator.translationState(
            from: 60,
            to: 120,
            targetOffsets: targetOffsets,
            thresholds: thresholds,
            currentTargetOffsetIndex: 0
        )

        XCTAssertEqual(state?.nextOffset, 120)
        XCTAssertEqual(state?.targetOffset, 200)
        XCTAssertEqual(state?.isDismissible, false)
    }

    func testTranslationStateWhenThereIsNoAreaBelow() {
        let targetOffsets: [CGFloat] = [56, 200]
        let thresholds: [CGFloat] = [36, 36, 36]

        let state = BottomSheetCalculator.translationState(
            from: 200,
            to: 250,
            targetOffsets: targetOffsets,
            thresholds: thresholds,
            currentTargetOffsetIndex: 1
        )

        XCTAssertEqual(state?.nextOffset, 250)
        XCTAssertEqual(state?.targetOffset, 200)
        XCTAssertEqual(state?.isDismissible, true)
    }

    func testTranslationStateToAreaAbove() {
        let targetOffsets: [CGFloat] = [56, 200]
        let thresholds: [CGFloat] = [36, 36, 36]

        let state = BottomSheetCalculator.translationState(
            from: 190,
            to: 140,
            targetOffsets: targetOffsets,
            thresholds: thresholds,
            currentTargetOffsetIndex: 1
        )

        XCTAssertEqual(state?.nextOffset, 140)
        XCTAssertEqual(state?.targetOffset, 56)
        XCTAssertEqual(state?.isDismissible, false)
    }

    func testTranslationStateWhenThereIsNoAreaAbove() {
        let targetOffsets: [CGFloat] = [56, 200]
        let thresholds: [CGFloat] = [36, 36, 36]

        let state = BottomSheetCalculator.translationState(
            from: 56,
            to: 10,
            targetOffsets: targetOffsets,
            thresholds: thresholds,
            currentTargetOffsetIndex: 0
        )

        XCTAssertEqual(state?.nextOffset, 56)
        XCTAssertEqual(state?.targetOffset, 56)
        XCTAssertEqual(state?.isDismissible, false)
    }
}
