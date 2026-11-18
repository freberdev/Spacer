import AppKit
import SpacerCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = GapStore(defaults: .standard)
    private lazy var items = GapItemsController(store: store)
    private var layoutPrinter: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.onChange = { [weak self] in self?.storeChanged() }
        if store.gaps.isEmpty {
            store.add()
        } else {
            items.sync()
        }
        // "-printLayout YES" on the command line prints where the gaps are, for development.
        if UserDefaults.standard.bool(forKey: "printLayout") { startPrintingLayout() }
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
