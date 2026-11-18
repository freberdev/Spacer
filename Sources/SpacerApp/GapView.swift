import AppKit
import SpacerCore

/// What is drawn in a gap: its line or dot, if it has one, and the faint frame that shows
/// where the gap is and how wide it is.
final class GapView: NSView {
    var showsFrame = false {
        didSet { if showsFrame != oldValue { needsDisplay = true } }
    }

    var style: GapStyle = .empty {
        didSet { if style != oldValue { needsDisplay = true } }
    }

    // Everything is drawn here, not through a layer, so the colours follow the menu bar's own
    // appearance: light over a dark wallpaper and dark over a light one.
    override func draw(_ dirtyRect: NSRect) {
        drawMarker()
        if showsFrame { drawFrame() }
    }

    private func drawMarker() {
        let centre = NSPoint(x: bounds.midX, y: bounds.midY)
        NSColor.labelColor.withAlphaComponent(0.35).setFill()
        switch style {
        case .line:
            NSBezierPath(roundedRect: NSRect(x: centre.x - 0.5, y: centre.y - 7, width: 1, height: 14),
                         xRadius: 0.5, yRadius: 0.5).fill()
        case .dot:
            NSBezierPath(ovalIn: NSRect(x: centre.x - 2, y: centre.y - 2, width: 4, height: 4)).fill()
        case .empty, .name:
            break
        }
    }

    private func drawFrame() {
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
