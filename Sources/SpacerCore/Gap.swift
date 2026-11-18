import Foundation

/// One empty space in the menu bar.
public struct Gap: Codable, Equatable, Identifiable, Sendable {
    public static let minWidth = 4
    public static let maxWidth = 400
    public static let defaultWidth = 24

    public let id: UUID
    public private(set) var width: Int

    public init(id: UUID = UUID(), width: Int = Gap.defaultWidth) {
        self.id = id
        self.width = Gap.clamped(width)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        width = Gap.clamped(try container.decode(Int.self, forKey: .width))
    }

    public mutating func setWidth(_ width: Int) {
        self.width = Gap.clamped(width)
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
