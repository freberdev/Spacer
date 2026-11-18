import Foundation

/// One empty space in the menu bar.
public struct Gap: Codable, Equatable, Identifiable, Sendable {
    public static let minWidth = 4
    public static let maxWidth = 400
    public static let defaultWidth = 24
    public static let maxNameLength = 30

    public let id: UUID
    public private(set) var width: Int
    /// The name as it was typed: one line, at most `maxNameLength` characters.
    public private(set) var name: String
    public var style: GapStyle

    public init(id: UUID = UUID(), width: Int = Gap.defaultWidth, name: String = "", style: GapStyle = .empty) {
        self.id = id
        self.width = Gap.clamped(width)
        self.name = Gap.cleaned(name)
        self.style = style
    }

    /// Reads a stored gap. A gap stored by the first version has no name and no style, and a
    /// later version may have stored a style this one does not know; both become an empty gap.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        width = Gap.clamped(try container.decode(Int.self, forKey: .width))
        name = Gap.cleaned((try? container.decodeIfPresent(String.self, forKey: .name)) ?? "")
        let storedStyle = (try? container.decodeIfPresent(String.self, forKey: .style)) ?? nil
        style = storedStyle.flatMap(GapStyle.init(rawValue:)) ?? .empty
    }

    public mutating func setWidth(_ width: Int) {
        self.width = Gap.clamped(width)
    }

    public mutating func setName(_ name: String) {
        self.name = Gap.cleaned(name)
    }

    /// The name without spaces around it, as it is shown.
    public var displayName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    /// The text the gap shows in the menu bar, if it shows any.
    public var visibleText: String? {
        guard style == .name, !displayName.isEmpty else { return nil }
        return displayName
    }

    /// How long the gap's status item is, given the width of the text it shows, if any.
    /// A name is never cut off: the gap grows to fit it.
    public func length(textWidth: Double?) -> Double {
        guard let textWidth, textWidth.isFinite, textWidth > 0 else { return Double(width) }
        return max(Double(width), textWidth.rounded(.up))
    }

    /// Makes a name one line and cuts it to the longest allowed. Spaces at the ends are kept,
    /// so a name can be typed one character at a time; `displayName` leaves them out.
    static func cleaned(_ name: String) -> String {
        let oneLine = name.map { $0.isNewline || ($0.isWhitespace && $0 != " ") ? " " : $0 }
        return String(String(oneLine).prefix(maxNameLength))
    }

    public static func clamped(_ width: Int) -> Int {
        min(max(width, minWidth), maxWidth)
    }

    /// Rounds to whole points. Values that are not numbers become the minimum.
    public static func clamped(_ width: Double) -> Int {
        guard !width.isNaN else { return minWidth }
        if width >= Double(maxWidth) { return maxWidth }
        if width <= Double(minWidth) { return minWidth }
        return clamped(Int(width.rounded()))
    }

    /// The name macOS stores this gap's place in the menu bar under.
    public var autosaveName: String {
        "gap-" + id.uuidString.lowercased()
    }
}
