import Foundation

/// Which gaps should show their frame because of the settings window.
///
/// A row can be pointed at and have its slider dragged at the same time. The frame stays
/// on until both have ended, whichever ends first.
public struct Highlights {
    private var hovered: Set<Gap.ID> = []
    private var editing: Set<Gap.ID> = []

    public init() {}

    public func isHighlighted(_ id: Gap.ID) -> Bool {
        hovered.contains(id) || editing.contains(id)
    }

    /// Returns whether the gap should show its frame after the change.
    @discardableResult
    public mutating func setHovered(_ id: Gap.ID, _ on: Bool) -> Bool {
        if on { hovered.insert(id) } else { hovered.remove(id) }
        return isHighlighted(id)
    }

    /// Returns whether the gap should show its frame after the change.
    @discardableResult
    public mutating func setEditing(_ id: Gap.ID, _ on: Bool) -> Bool {
        if on { editing.insert(id) } else { editing.remove(id) }
        return isHighlighted(id)
    }

    /// Forgets everything and returns the gaps that were highlighted.
    public mutating func clear() -> Set<Gap.ID> {
        let all = hovered.union(editing)
        hovered = []
        editing = []
        return all
    }
}
