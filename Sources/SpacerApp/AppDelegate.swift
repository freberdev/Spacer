import AppKit
import SpacerCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = GapStore(defaults: .standard)
    private let preferences = Preferences(defaults: .standard)
    private lazy var items = GapItemsController(store: store)
    private lazy var settingsModel = SettingsModel(store: store, items: items) { [weak self] in self?.addGap() }
    private lazy var settings = SettingsWindowController(model: settingsModel)
    private var layoutPrinter: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Two copies would each put the same gaps in the menu bar and overwrite each other's list.
        if handOverToRunningCopy() {
            NSApp.terminate(nil)
            return
        }
        installMainMenu()

        // A gap that is only there when the app has been started by hand is of little use.
        if LoginItem.isInstalled && !preferences.didRequestLoginItem {
            preferences.didRequestLoginItem = true
            try? LoginItem.setEnabled(true)
        }

        store.onChange = { [weak self] in self?.storeChanged() }
        items.populateMenu = { [weak self] menu, id in self?.populate(menu, for: id) }

        let isFirstRun = !preferences.didShowWelcome
        if isFirstRun && store.gaps.isEmpty {
            store.add()
        } else {
            items.sync()
        }
        if isFirstRun {
            preferences.didShowWelcome = true
            store.gaps.forEach { items.flash($0.id) }
            settings.show()
        } else if store.gaps.isEmpty {
            // Without gaps nothing of the app is on screen.
            settings.show()
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

    /// Opening Spacer again while it is running, from Spotlight or Finder, shows the settings.
    /// That is the way in when no gap can be clicked.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        settings.show()
        return false
    }

    /// If another copy of Spacer is running, asks it to show its settings and returns true.
    /// That happens when the app is opened from a second place, such as the disk image.
    private func handOverToRunningCopy() -> Bool {
        guard let identifier = Bundle.main.bundleIdentifier else { return false }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .filter { $0 != NSRunningApplication.current }
        guard let other = others.first else { return false }
        if let url = other.bundleURL { NSWorkspace.shared.open(url) }
        return true
    }

    /// The menu bar never shows this menu, since Spacer has no Dock icon, but it is what makes
    /// ⌘W and ⌘Q work in the settings window.
    private func installMainMenu() {
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: L("menu.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let windowMenu = NSMenu(title: L("mainmenu.window"))
        windowMenu.addItem(withTitle: L("mainmenu.close"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        let main = NSMenu()
        for submenu in [appMenu, windowMenu] {
            let item = NSMenuItem()
            item.submenu = submenu
            main.addItem(item)
        }
        NSApp.mainMenu = main
    }

    private func storeChanged() {
        items.sync()
        settingsModel.refresh()
        if store.gaps.isEmpty { settings.show() }
    }

    private func populate(_ menu: NSMenu, for id: Gap.ID) {
        guard let gap = store.gaps.first(where: { $0.id == id }) else { return }
        GapMenu.populate(menu, width: gap.width, actions: GapMenu.Actions(
            setWidth: { [weak self] in self?.store.setWidth($0, for: id) },
            addGap: { [weak self] in self?.addGap(leftOf: id) },
            // Not from inside the menu's own action: removing the gap takes the menu with it.
            remove: { [weak self] in Task { @MainActor in self?.store.remove(id) } },
            openSettings: { [weak self] in self?.settings.show() },
            quit: { NSApp.terminate(nil) }))
    }

    /// Adds a gap and shows its frame for a moment, so it can be found.
    private func addGap(leftOf neighbour: Gap.ID? = nil) {
        let gap = store.add(leftOf: neighbour)
        items.flash(gap.id)
    }

    private func startPrintingLayout() {
        layoutPrinter = Task { [weak self] in
            var last: String?
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
