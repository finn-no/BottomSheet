////
////  File.swift
////  bottom-sheet-delegate
////
////  Created by Granheim Brustad , Henrik on 04/11/2019.
////  Copyright © 2019 Henrik Brustad. All rights reserved.
////
//
//import Foundation
//import CoreGraphics
//
//
//
//struct BottomSheetStateArea {
//    let bounds: CGRect
//    let state: BottomSheetState
//}
//
//struct BottomSheetStateMap {
//    let areas: [BottomSheetStateArea]
//
//    func state(for location: CGPoint) -> BottomSheetState? {
//        let area = areas.first { area -> Bool in
//            area.bounds.contains(location)
//        }
//
//        return area?.state
//    }
//}
//
//struct BottomSheetModel {
//    let height: CGFloat
//    let stateMap: BottomSheetStateMap
//}
//
//
//
