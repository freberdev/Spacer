import AppKit
import SpacerCore

/// Keeps the status items in the menu bar in step with the stored gaps.
@MainActor
final class GapItemsController {
    /// Fills in the menu of the gap with the given id.
    var populateMenu: ((NSMenu, Gap.ID) -> Void)?

    private let store: GapStore
    private var items: [Gap.ID: GapItem] = [:]

    init(store: GapStore) {
        self.store = store
    }

    /// Creates, removes and resizes status items so the menu bar matches the store.
    func sync() {
        let wanted = Set(store.gaps.map(\.id))
        for (id, item) in items where !wanted.contains(id) {
            item.remove()
            items[id] = nil
        }
        for gap in store.gaps {
            if let item = items[gap.id] {
                if item.width != gap.width { item.width = gap.width }
            } else {
                let item = GapItem(gap: gap)
                item.populateMenu = { [weak self] menu in self?.populateMenu?(menu, gap.id) }
                items[gap.id] = item
            }
        }
    }

    func setHighlighted(_ id: Gap.ID, _ on: Bool) {
        items[id]?.isHighlighted = on
    }

    func flash(_ id: Gap.ID) {
        items[id]?.flashOutline()
    }

    func openMenu(_ id: Gap.ID) {
        items[id]?.openMenu()
    }

    /// The left edge of each gap macOS has placed.
    func positions() -> [Gap.ID: Double] {
        items.compactMapValues(\.screenX)
    }

    /// The gaps that are not in view right now.
    func hidden() -> Set<Gap.ID> {
        Set(items.filter { !$0.value.isShowing }.keys)
    }

    /// One line per gap, for the `-printLayout` development option.
    func layoutDescription() -> String {
        GapOrder.leftToRight(store.gaps, positions: positions()).map { gap in
            let x = items[gap.id]?.screenX.map { String(Int($0)) } ?? "-"
            let showing = items[gap.id]?.isShowing ?? false
            return "gap \(gap.id.uuidString.lowercased()) width=\(gap.width) x=\(x) showing=\(showing)"
        }.joined(separator: "\n")
    }
}
