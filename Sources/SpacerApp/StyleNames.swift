import SpacerCore

extension GapStyle {
    /// What the style is called in menus.
    var title: String {
        switch self {
        case .empty: L("style.empty")
        case .line: L("style.line")
        case .dot: L("style.dot")
        case .name: L("style.name")
        }
    }
}
