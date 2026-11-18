import AppKit
import SpacerCore

/// The menu that opens when a gap is clicked.
@MainActor
enum GapMenu {
    struct Actions {
        var setWidth: (Int) -> Void
        var setStyle: (GapStyle) -> Void
        var addGap: () -> Void
        var remove: () -> Void
        var openSettings: () -> Void
        var quit: () -> Void
    }

    static func populate(_ menu: NSMenu, gap: Gap, actions: Actions) {
        menu.removeAllItems()

        if !gap.displayName.isEmpty {
            menu.addItem(.sectionHeader(title: gap.displayName))
        }
        let slider = NSMenuItem()
        slider.view = WidthSliderView(width: gap.width, onChange: actions.setWidth)
        menu.addItem(slider)

        let styles = NSMenu()
        for style in GapStyle.allCases {
            let item = ActionItem(style.title) { actions.setStyle(style) }
            item.state = style == gap.style ? .on : .off
            styles.addItem(item)
        }
        let showAs = NSMenuItem(title: L("menu.showAs"), action: nil, keyEquivalent: "")
        showAs.submenu = styles
        menu.addItem(showAs)

        menu.addItem(.separator())
        menu.addItem(ActionItem(L("menu.add"), handler: actions.addGap))
        menu.addItem(ActionItem(L("menu.remove"), handler: actions.remove))
        menu.addItem(.separator())
        menu.addItem(ActionItem(L("menu.settings"), handler: actions.openSettings))
        menu.addItem(ActionItem(L("menu.quit"), handler: actions.quit))
    }
}

/// A menu item that runs a closure.
private final class ActionItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: "")
        target = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError("not used") }

    @objc private func run() { handler() }
}

/// The row with the width slider: a label, the slider and the width in points.
private final class WidthSliderView: NSView {
    private let slider = NSSlider()
    private let value = NSTextField(labelWithString: "")
    private let onChange: (Int) -> Void

    init(width: Int, onChange: @escaping (Int) -> Void) {
        self.onChange = onChange
        super.init(frame: NSRect(x: 0, y: 0, width: 280, height: 30))

        let label = NSTextField(labelWithString: L("menu.width"))
        label.font = .menuFont(ofSize: 0)

        slider.minValue = 0
        slider.maxValue = 1
        slider.doubleValue = WidthScale.fraction(for: width)
        slider.isContinuous = true
        slider.controlSize = .small
        slider.target = self
        slider.action = #selector(sliderMoved)
        slider.setAccessibilityLabel(L("menu.width"))

        value.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        value.textColor = .secondaryLabelColor
        value.alignment = .right
        value.stringValue = String(width)

        let row = NSStackView(views: [label, slider, value])
        row.orientation = .horizontal
        row.spacing = 10
        row.edgeInsets = NSEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            value.widthAnchor.constraint(equalToConstant: 30),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    @objc private func sliderMoved() {
        let width = WidthScale.width(at: slider.doubleValue)
        value.stringValue = String(width)
        onChange(width)
    }
}
