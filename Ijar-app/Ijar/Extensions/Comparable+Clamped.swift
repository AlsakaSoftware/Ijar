import Foundation

extension Comparable {
    /// Clamps the value to the specified range
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
