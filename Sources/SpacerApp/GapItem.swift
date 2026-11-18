import AppKit
import SpacerCore

/// One gap in the menu bar: an empty status item that macOS places and remembers by name.
@MainActor
final class GapItem: NSObject, NSMenuDelegate {
    let id: Gap.ID
    /// Fills in the gap's menu each time it is about to open.
    var populateMenu: ((NSMenu) -> Void)?

    private let statusItem: NSStatusItem
    private let view = GapView()
    private var gap: Gap
    private var isHovered = false { didSet { updateOutline() } }
    private var isFlashing = false { didSet { updateOutline() } }
    private var flash: Task<Void, Never>?

    var isHighlighted = false { didSet { updateOutline() } }

    init(gap: Gap) {
        id = gap.id
        self.gap = gap
        statusItem = NSStatusBar.system.statusItem(withLength: CGFloat(gap.width))
        super.init()
        // The place stored under this name is applied when the name is set.
        statusItem.autosaveName = gap.autosaveName

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        guard let button = statusItem.button else { return }
        view.frame = button.bounds
        view.autoresizingMask = [.width, .height]
        button.addSubview(view)
        button.addTrackingArea(NSTrackingArea(
            rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
        show(gap)
    }

    /// Takes over the width, the style and the name of the gap.
    func apply(_ gap: Gap) {
        guard gap != self.gap else { return }
        self.gap = gap
        show(gap)
    }

    private func show(_ gap: Gap) {
        view.style = gap.style
        var length = CGFloat(gap.width)
        if let text = gap.visibleText {
            let title = NSAttributedString(string: text, attributes: [
                .font: NSFont.menuBarFont(ofSize: 0),
                .foregroundColor: NSColor.secondaryLabelColor,
            ])
            statusItem.button?.attributedTitle = title
            // A name is never cut off: the gap grows to fit it.
            length = max(length, title.size().width.rounded(.up))
        } else {
            statusItem.button?.title = ""
        }
        statusItem.length = length
        let name = gap.displayName
        statusItem.button?.setAccessibilityLabel(name.isEmpty ? L("gap.accessibility") : name)
    }

    /// The left edge of the gap's place in the menu bar, also when the gap is not in view.
    /// Nil only when the status item has no window.
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

    func menuDidClose(_ menu: NSMenu) {
        // No exit event arrives when the pointer left while the menu was open.
        isHovered = statusItem.button?.window?.frame.contains(NSEvent.mouseLocation) ?? false
    }

    /// Opens the gap's menu, as a click would.
    func openMenu() {
        statusItem.button?.performClick(nil)
    }

    @objc(mouseEntered:) func mouseEntered(with event: NSEvent) { isHovered = true }
    @objc(mouseExited:) func mouseExited(with event: NSEvent) { isHovered = false }

    private func updateOutline() {
        view.showsFrame = isHovered || isHighlighted || isFlashing
    }
}
