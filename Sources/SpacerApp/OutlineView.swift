import AppKit

/// The faint frame that shows where a gap is and how wide it is.
final class OutlineView: NSView {
    var isShown = false {
        didSet {
            guard isShown != oldValue else { return }
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard isShown else { return }
        // Drawn here, not through a layer, so the colour follows the menu bar's own
        // appearance: light over a dark wallpaper and dark over a light one.
        let frame = bounds.insetBy(dx: 0.5, dy: 4.5)
        guard frame.width > 0, frame.height > 0 else { return }
        let radius = min(5, frame.width / 2)
        let path = NSBezierPath(roundedRect: frame, xRadius: radius, yRadius: radius)
        NSColor.labelColor.withAlphaComponent(0.10).setFill()
        path.fill()
        NSColor.labelColor.withAlphaComponent(0.45).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    /// Clicks go through to the status item's button.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
