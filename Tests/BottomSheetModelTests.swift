//
//  Copyright © 2019 FINN.no. All rights reserved.
//

import XCTest
@testable import BottomSheet

final class BottomSheetModelTests: XCTestCase {

    func testRangeModel() {
        let rangeModel = RangeModel(
            targetOffset: 500,
            range: 300 ..< 600,
            isDismissible: false
        )

        XCTAssertFalse(rangeModel.contains(offset: 200))
        XCTAssertTrue(rangeModel.contains(offset: 400))
        XCTAssertFalse(rangeModel.contains(offset: 700))
        XCTAssertEqual(rangeModel.nextOffset(for: 400), 400)
    }

    func testLowerLimitModel() {
        let targetOffset: CGFloat = 200

        let lowerLimitModel = LimitModel(
            targetOffset: targetOffset,
            isDismissible: false,
            compare: <
        )

        XCTAssertTrue(lowerLimitModel.contains(offset: 100))
        XCTAssertFalse(lowerLimitModel.contains(offset: 300))
        XCTAssertEqual(lowerLimitModel.nextOffset(for: 100), targetOffset)
    }

    func testUpperLimitModel() {
        let targetOffset: CGFloat = 700

        let upperLimitModel = LimitModel(
            targetOffset: targetOffset,
            isDismissible: false,
            compare: >=
        )

        XCTAssertFalse(upperLimitModel.contains(offset: 300))
        XCTAssertTrue(upperLimitModel.contains(offset: 800))
        XCTAssertEqual(upperLimitModel.nextOffset(for: 800), targetOffset)
    }
}
