import Foundation

/// The order gaps are listed in: as they lie in the menu bar, from left to right.
public enum GapOrder {
    /// `positions` holds the left edge of each gap that is on screen. Gaps without one come
    /// last. Gaps that tie keep the order they were given in.
    public static func leftToRight(_ gaps: [Gap], positions: [Gap.ID: Double]) -> [Gap] {
        let placed = gaps.enumerated().map { index, gap -> (gap: Gap, x: Double, index: Int) in
            let x = positions[gap.id] ?? .infinity
            return (gap, x.isNaN ? .infinity : x, index)
        }
        return placed
            .sorted { $0.x == $1.x ? $0.index < $1.index : $0.x < $1.x }
            .map(\.gap)
    }
}
