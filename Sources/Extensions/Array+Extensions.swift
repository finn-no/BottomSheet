import Foundation

extension Array {
    // Returns an Optional that will be nil if index < count
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : .none
    }
}
