//
//  Copyright © 2019 FINN.no. All rights reserved.
//

import XCTest
@testable import BottomSheet

final class BottomSheetModelTests: XCTestCase {

    func testRangeTarget() {
        let rangeModel = RangeTarget(
            targetOffset: 500,
            range: 300 ..< 600,
            isBottomTarget: false
        )

        XCTAssertFalse(rangeModel.contains(offset: 200))
        XCTAssertTrue(rangeModel.contains(offset: 400))
        XCTAssertFalse(rangeModel.contains(offset: 700))
        XCTAssertEqual(rangeModel.nextOffset(for: 400), 400)
    }

    func testLowerLimitTargetWithStopBehaviour() {
        let targetOffset: CGFloat = 200

        let lowerLimitModel = LimitTarget(
            targetOffset: targetOffset,
            bound: targetOffset,
            behavior: .stop,
            isBottomTarget: false,
            compare: <
        )

        XCTAssertTrue(lowerLimitModel.contains(offset: 100))
        XCTAssertFalse(lowerLimitModel.contains(offset: 300))
        XCTAssertEqual(lowerLimitModel.nextOffset(for: 100), targetOffset)
    }

    func testLowerLimitTargetWithRubberBandBehaviour() {
        let bound: CGFloat = 300
        let radius: CGFloat = 75

        let lowerLimitModel = LimitTarget(
            targetOffset: bound,
            bound: bound,
            behavior: .rubberBand(radius: radius),
            isBottomTarget: false,
            compare: <
        )

        XCTAssertTrue(lowerLimitModel.contains(offset: 200))
        XCTAssertFalse(lowerLimitModel.contains(offset: 500))

        let offset: CGFloat = 200
        let distance = offset - bound
        let nextOffset = radius * (1 - exp(-abs(distance) / radius))
        XCTAssertEqual(lowerLimitModel.nextOffset(for: offset), bound - nextOffset)
    }

    func testUpperLimitTargetWithLinearBehaviour() {
        let targetOffset: CGFloat = 700

        let upperLimitModel = LimitTarget(
            targetOffset: targetOffset,
            bound: 700,
            behavior: .linear,
            isBottomTarget: false,
            compare: >=
        )

        XCTAssertFalse(upperLimitModel.contains(offset: 300))
        XCTAssertTrue(upperLimitModel.contains(offset: 800))
        XCTAssertEqual(upperLimitModel.nextOffset(for: 800), 800)
    }
}
