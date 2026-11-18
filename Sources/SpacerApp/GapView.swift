import AppKit
import SpacerCore

/// What is drawn in a gap: its line, dot or name, if it shows one, and the faint frame that
/// shows where the gap is and how wide it is.
final class GapView: NSView {
    var showsFrame = false {
        didSet { if showsFrame != oldValue { needsDisplay = true } }
    }

    var style: GapStyle = .empty {
        didSet { if style != oldValue { needsDisplay = true } }
    }

    /// The name to show, when the gap shows its name.
    var text: String? {
        didSet { if text != oldValue { needsDisplay = true } }
    }

    /// The name as it is drawn: in the menu bar's font, dimmed, so it reads as a label
    /// and not as an icon.
    static func title(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font: NSFont.menuBarFont(ofSize: 0),
            .foregroundColor: NSColor.secondaryLabelColor,
        ])
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
            // On a whole point, so the line is one sharp column on a display that is not Retina.
            let x = (centre.x - 0.5).rounded(.down)
            NSBezierPath(roundedRect: NSRect(x: x, y: centre.y - 7, width: 1, height: 14),
                         xRadius: 0.5, yRadius: 0.5).fill()
        case .dot:
            NSBezierPath(ovalIn: NSRect(x: centre.x - 2, y: centre.y - 2, width: 4, height: 4)).fill()
        case .name:
            // Drawn here and not as the button's title, which the button may wrap or cut.
            guard let text else { break }
            let title = GapView.title(text)
            let size = title.size()
            title.draw(at: NSPoint(x: centre.x - size.width / 2, y: centre.y - size.height / 2))
        case .empty:
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
