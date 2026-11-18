import AppKit
import SpacerCore

/// One gap in the menu bar: an empty status item that macOS places and remembers by name.
@MainActor
final class GapItem: NSObject, NSMenuDelegate {
    let id: Gap.ID
    /// Fills in the gap's menu each time it is about to open.
    var populateMenu: ((NSMenu) -> Void)?

    private let statusItem: NSStatusItem
    private let outline = OutlineView()
    private var isHovered = false { didSet { updateOutline() } }
    private var isFlashing = false { didSet { updateOutline() } }
    private var flash: Task<Void, Never>?

    var isHighlighted = false { didSet { updateOutline() } }

    var width: Int {
        get { Int(statusItem.length) }
        set { statusItem.length = CGFloat(newValue) }
    }

    init(gap: Gap) {
        id = gap.id
        statusItem = NSStatusBar.system.statusItem(withLength: CGFloat(gap.width))
        super.init()
        // The place stored under this name is applied when the name is set.
        statusItem.autosaveName = gap.autosaveName

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        guard let button = statusItem.button else { return }
        button.setAccessibilityLabel(L("gap.accessibility"))
        outline.frame = button.bounds
        outline.autoresizingMask = [.width, .height]
        button.addSubview(outline)
        button.addTrackingArea(NSTrackingArea(
            rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }

    /// The left edge of the gap on screen, or nil before macOS has placed it.
    var screenX: Double? {
        guard let window = statusItem.button?.window else { return nil }
        return Double(window.frame.minX)
    }

    /// False when the gap is not in view, for example behind the camera housing or when
    /// the menu bar has no room for it.
    var isShowing: Bool {
        guard statusItem.isVisible, let window = statusItem.button?.window else { return false }
        return window.occlusionState.contains(.visible)
    }

    /// Shows the frame for a few seconds, so a new gap can be found.
    func flashOutline(for duration: Duration = .seconds(3)) {
        flash?.cancel()
        isFlashing = true
        flash = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.isFlashing = false
        }
    }

    func remove() {
        flash?.cancel()
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        populateMenu?(menu)
    }

    /// Opens the gap's menu, as a click would.
    func openMenu() {
        statusItem.button?.performClick(nil)
    }

    @objc(mouseEntered:) func mouseEntered(with event: NSEvent) { isHovered = true }
    @objc(mouseExited:) func mouseExited(with event: NSEvent) { isHovered = false }

    private func updateOutline() {
        outline.isShown = isHovered || isHighlighted || isFlashing
    }
}
