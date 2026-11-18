import Foundation

/// Where a new gap goes in the menu bar.
///
/// macOS keeps the place of a status item as a number in the app's settings, under a key
/// that ends with the item's autosave name. A larger number is further to the left. An item
/// without a stored place is put at the far left, where a full menu bar hides it, so every
/// new gap gets its place written before the status item is created.
public enum GapPlacement {
    /// Positions closer to zero than this are not used. Zero itself means "no place stored".
    public static let smallestPosition = 1.0 / 1024

    public static func key(for autosaveName: String) -> String {
        "NSStatusItem Preferred Position " + autosaveName
    }

    /// The place just to the left of a gap at `neighbour`. `others` are the places of the app's own gaps.
    public static func position(leftOf neighbour: Double, others: [Double]) -> Double {
        let nextToTheLeft = others.filter { $0 > neighbour && $0 - neighbour <= 2 }.min()
        guard let nextToTheLeft else { return neighbour + 1 }
        return (neighbour + nextToTheLeft) / 2
    }

    /// The place furthest to the right among the icons of apps, next to the system's own.
    public static func rightmost(others: [Double]) -> Double {
        guard let lowest = others.filter({ $0 > 0 }).min(), lowest <= 1 else { return 1 }
        return max(lowest / 2, smallestPosition)
    }
}
