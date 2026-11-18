import AppKit
import SpacerCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = GapStore(defaults: .standard)
    private lazy var items = GapItemsController(store: store)
    private var layoutPrinter: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.onChange = { [weak self] in self?.storeChanged() }
        items.populateMenu = { [weak self] menu, id in self?.populate(menu, for: id) }
        if store.gaps.isEmpty {
            store.add()
        } else {
            items.sync()
        }
        // Two options on the command line help during development:
        // "-printLayout YES" prints where the gaps are, and "-openMenu YES" opens the first gap's menu.
        if UserDefaults.standard.bool(forKey: "printLayout") { startPrintingLayout() }
        if UserDefaults.standard.bool(forKey: "openMenu"), let first = store.gaps.first {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(1.5))
                self?.items.openMenu(first.id)
            }
        }
    }

    private func populate(_ menu: NSMenu, for id: Gap.ID) {
        guard let gap = store.gaps.first(where: { $0.id == id }) else { return }
        GapMenu.populate(menu, width: gap.width, actions: GapMenu.Actions(
            setWidth: { [weak self] in self?.store.setWidth($0, for: id) },
            addGap: { [weak self] in self?.addGap(leftOf: id) },
            remove: { [weak self] in self?.store.remove(id) },
            openSettings: { [weak self] in self?.showSettings() },
            quit: { NSApp.terminate(nil) }))
    }

    /// Adds a gap and shows its frame for a moment, so it can be found.
    private func addGap(leftOf neighbour: Gap.ID? = nil) {
        let gap = store.add(leftOf: neighbour)
        items.flash(gap.id)
    }

    private func showSettings() {
    }

    private func storeChanged() {
        items.sync()
    }

    private func startPrintingLayout() {
        layoutPrinter = Task { [weak self] in
            var last = ""
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self else { return }
                let layout = self.items.layoutDescription()
                if layout != last {
                    last = layout
                    print(layout.isEmpty ? "no gaps" : layout)
                    print("--")
                    fflush(stdout)
                }
            }
        }
    }
}
