import Observation
import SpacerCore

/// What the settings window shows and does.
@MainActor
@Observable
final class SettingsModel {
    struct Row: Identifiable, Equatable {
        let id: Gap.ID
        var width: Int
        /// The gap is not in view in the menu bar right now.
        var isHidden: Bool
    }

    /// The gaps as they lie in the menu bar, from left to right.
    private(set) var rows: [Row] = []
    private(set) var openAtLogin = LoginItem.isEnabled
    private(set) var loginItemFailed = false

    @ObservationIgnored private let store: GapStore
    @ObservationIgnored private let items: GapItemsController
    @ObservationIgnored private let addGap: () -> Void

    init(store: GapStore, items: GapItemsController, addGap: @escaping () -> Void) {
        self.store = store
        self.items = items
        self.addGap = addGap
        refresh()
    }

    /// Reads the gaps, their order and whether they are in view again.
    func refresh() {
        let hidden = items.hidden()
        let current = GapOrder.leftToRight(store.gaps, positions: items.positions()).map {
            Row(id: $0.id, width: $0.width, isHidden: hidden.contains($0.id))
        }
        if current != rows { rows = current }
        let enabled = LoginItem.isEnabled
        if enabled != openAtLogin { openAtLogin = enabled }
    }

    func add() {
        addGap()
    }

    func remove(_ id: Gap.ID) {
        store.remove(id)
    }

    func setWidth(_ width: Int, for id: Gap.ID) {
        store.setWidth(width, for: id)
    }

    /// Shows or hides the frame around a gap in the menu bar, so it is clear which row is which.
    func setHighlighted(_ id: Gap.ID, _ on: Bool) {
        items.setHighlighted(id, on)
    }

    func clearHighlights() {
        rows.forEach { items.setHighlighted($0.id, false) }
    }

    func setOpenAtLogin(_ on: Bool) {
        do {
            try LoginItem.setEnabled(on)
            loginItemFailed = false
        } catch {
            loginItemFailed = true
        }
        openAtLogin = LoginItem.isEnabled
    }
}
