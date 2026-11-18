import AppKit
import SwiftUI

/// The settings window. Spacer has no Dock icon, so the window is created and brought forward
/// by hand; SwiftUI's own Settings scene tends to open behind other apps in that situation.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let model: SettingsModel
    private var window: NSWindow?
    private var refresher: Task<Void, Never>?

    init(model: SettingsModel) {
        self.model = model
    }

    func show() {
        if window == nil {
            let content = NSHostingController(rootView: SettingsView(model: model))
            // The window follows the content as gaps are added and removed.
            content.sizingOptions = [.preferredContentSize]
            let window = NSWindow(contentViewController: content)
            window.title = L("settings.title")
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.delegate = self
            // Sized before it is centred; otherwise the corner of an empty window ends up in the middle.
            window.setContentSize(content.view.fittingSize)
            window.center()
            self.window = window
        }
        model.refresh()
        startRefreshing()
        // Spacer is not the active app when this is called from a gap's menu.
        NSApp.activateInsistently()
        window?.makeKeyAndOrderFront(nil)
        // Activation is only a request. The window comes forward even when it is not granted.
        window?.orderFrontRegardless()
        // Otherwise the first name field takes the keyboard, and looks selected, every time.
        window?.makeFirstResponder(nil)
    }

    func windowWillClose(_ notification: Notification) {
        refresher?.cancel()
        refresher = nil
        model.clearHighlights()
    }

    /// The order of the rows follows the menu bar, which changes when a gap is dragged.
    /// Nothing tells the app about that, so the window looks again twice a second while it is open.
    private func startRefreshing() {
        guard refresher == nil else { return }
        refresher = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                self?.model.refresh()
            }
        }
    }
}

extension NSApplication {
    /// Makes Spacer the active app even when another app is in front.
    ///
    /// The cooperative `activate()` is only a request, and it is ignored when Spacer is not
    /// already active, which is always the case for an app that lives in the menu bar.
    func activateInsistently() {
        (self as InsistentActivation).activate(ignoringOtherApps: true)
    }
}

/// Reaches `activate(ignoringOtherApps:)` without a deprecation warning at the call site.
@MainActor
private protocol InsistentActivation {
    func activate(ignoringOtherApps flag: Bool)
}

extension NSApplication: InsistentActivation {}
