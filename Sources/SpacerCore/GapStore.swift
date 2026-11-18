import Foundation

/// The list of gaps, kept in the app's settings.
@MainActor
public final class GapStore {
    public static let storageKey = "gaps"

    /// In the order the gaps were created.
    public private(set) var gaps: [Gap]
    public var onChange: (@MainActor () -> Void)?

    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        gaps = GapStore.load(from: defaults)
    }

    /// Adds a gap and stores its place in the menu bar: just left of the gap `leftOf`,
    /// or furthest to the right when no such gap has a stored place.
    @discardableResult
    public func add(width: Int = Gap.defaultWidth, leftOf neighbourID: Gap.ID? = nil) -> Gap {
        let gap = Gap(width: width)
        let others = gaps.compactMap { position(of: $0) }
        let neighbour = gaps.first { $0.id == neighbourID }.flatMap { position(of: $0) }
        let place = neighbour.map { GapPlacement.position(leftOf: $0, others: others) }
            ?? GapPlacement.rightmost(others: others)
        defaults.set(place, forKey: GapPlacement.key(for: gap.autosaveName))
        gaps.append(gap)
        changed()
        return gap
    }

    public func setWidth(_ width: Int, for id: Gap.ID) {
        guard let index = gaps.firstIndex(where: { $0.id == id }) else { return }
        let before = gaps[index].width
        gaps[index].setWidth(width)
        guard gaps[index].width != before else { return }
        changed()
    }

    /// Removes the gap and everything macOS has stored about its status item.
    public func remove(_ id: Gap.ID) {
        guard let index = gaps.firstIndex(where: { $0.id == id }) else { return }
        let suffix = " " + gaps[index].autosaveName
        gaps.remove(at: index)
        for key in defaults.dictionaryRepresentation().keys where key.hasSuffix(suffix) {
            defaults.removeObject(forKey: key)
        }
        changed()
    }

    /// The place macOS has stored for the gap, if any.
    public func position(of gap: Gap) -> Double? {
        let value = (defaults.object(forKey: GapPlacement.key(for: gap.autosaveName)) as? NSNumber)?.doubleValue
        guard let value, value > 0 else { return nil }
        return value
    }

    private func changed() {
        if let data = try? JSONEncoder().encode(gaps) {
            defaults.set(data, forKey: GapStore.storageKey)
        }
        onChange?()
    }

    private static func load(from defaults: UserDefaults) -> [Gap] {
        guard let data = defaults.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([Gap].self, from: data) else { return [] }
        var seen = Set<Gap.ID>()
        return stored.filter { seen.insert($0.id).inserted }
    }
}
