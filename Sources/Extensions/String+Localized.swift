//
//  Copyright © FINN.no. All rights reserved.
//

import Foundation

#if !SWIFT_PACKAGE
extension Bundle {
    static var module: Bundle { Bundle(for: BottomSheetView.self) }
}
#endif

extension String {
    func localized() -> String {
        NSLocalizedString(self, tableName: nil, bundle: .module, value: "", comment: "")
    }
}
