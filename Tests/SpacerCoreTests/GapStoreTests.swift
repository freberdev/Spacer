import Foundation
import Testing
@testable import SpacerCore

@MainActor @Suite struct GapStoreTests {
    let temporary = TemporaryDefaults()
    var defaults: UserDefaults { temporary.defaults }

    private func positionKey(_ gap: Gap) -> String {
        "NSStatusItem Preferred Position " + gap.autosaveName
    }

    @Test func startsEmpty() {
        defer { temporary.remove() }
        #expect(GapStore(defaults: defaults).gaps.isEmpty)
    }

    @Test func addPersists() {
        defer { temporary.remove() }
        let gap = GapStore(defaults: defaults).add(width: 60)
        #expect(GapStore(defaults: defaults).gaps == [gap])
        #expect(gap.width == 60)
    }

    @Test func addKeepsCreationOrder() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let first = store.add()
        let second = store.add()
        #expect(store.gaps == [first, second])
    }

    @Test func setWidthPersistsAndClamps() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let gap = store.add()
        store.setWidth(80, for: gap.id)
        #expect(GapStore(defaults: defaults).gaps.first?.width == 80)
        store.setWidth(9999, for: gap.id)
        #expect(GapStore(defaults: defaults).gaps.first?.width == 400)
    }

    @Test func setWidthForUnknownIdDoesNothing() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let gap = store.add()
        var changes = 0
        store.onChange = { changes += 1 }
        store.setWidth(80, for: UUID())
        #expect(store.gaps == [gap])
        #expect(changes == 0)
    }

    @Test func settingSameWidthDoesNotNotify() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let gap = store.add(width: 50)
        var changes = 0
        store.onChange = { changes += 1 }
        store.setWidth(50, for: gap.id)
        store.setWidth(9999, for: gap.id)
        store.setWidth(400, for: gap.id)
        #expect(changes == 1)
    }

    @Test func removePersists() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let first = store.add()
        let second = store.add()
        store.remove(first.id)
        #expect(GapStore(defaults: defaults).gaps == [second])
    }

    @Test func removingTwiceIsHarmless() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let gap = store.add()
        var changes = 0
        store.onChange = { changes += 1 }
        store.remove(gap.id)
        store.remove(gap.id)
        #expect(store.gaps.isEmpty)
        #expect(changes == 1)
    }

    @Test func removeDeletesSystemKeysForThatGapOnly() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let gone = store.add()
        let kept = store.add()
        for gap in [gone, kept] {
            defaults.set(120.0, forKey: "NSStatusItem Preferred Position " + gap.autosaveName)
            defaults.set(true, forKey: "NSStatusItem Visible " + gap.autosaveName)
            defaults.set(true, forKey: "NSStatusItem VisibleCC " + gap.autosaveName)
        }
        store.remove(gone.id)
        let keys = defaults.persistentDomain(forName: temporary.name)?.keys.sorted() ?? []
        #expect(keys.filter { $0.hasSuffix(gone.autosaveName) }.isEmpty)
        #expect(keys.filter { $0.hasSuffix(kept.autosaveName) }.count == 3)
        #expect(keys.contains(GapStore.storageKey))
    }

    @Test func unreadableDataGivesEmptyList() {
        defer { temporary.remove() }
        defaults.set("not a list", forKey: GapStore.storageKey)
        #expect(GapStore(defaults: defaults).gaps.isEmpty)
        defaults.set(Data([0xFF, 0x00, 0x7B]), forKey: GapStore.storageKey)
        let store = GapStore(defaults: defaults)
        #expect(store.gaps.isEmpty)
        let gap = store.add()
        #expect(GapStore(defaults: defaults).gaps == [gap])
    }

    @Test func duplicateIdsAreDropped() throws {
        defer { temporary.remove() }
        let id = UUID()
        let stored = [Gap(id: id, width: 30), Gap(id: id, width: 90), Gap(width: 50)]
        defaults.set(try JSONEncoder().encode(stored), forKey: GapStore.storageKey)
        let gaps = GapStore(defaults: defaults).gaps
        #expect(gaps.count == 2)
        #expect(gaps.first == stored[0])
        #expect(gaps.last == stored[2])
    }

    @Test func notifiesOncePerChange() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        var changes = 0
        store.onChange = { changes += 1 }
        let gap = store.add()
        #expect(changes == 1)
        store.setWidth(100, for: gap.id)
        #expect(changes == 2)
        store.remove(gap.id)
        #expect(changes == 3)
    }

    @Test func manyGaps() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let added = (0..<200).map { store.add(width: 4 + $0) }
        #expect(GapStore(defaults: defaults).gaps == added)
        added.forEach { store.remove($0.id) }
        #expect(GapStore(defaults: defaults).gaps.isEmpty)
        let leftovers = defaults.persistentDomain(forName: temporary.name)?.keys.filter { $0.contains("gap-") } ?? []
        #expect(leftovers.isEmpty)
    }

    @Test func rapidWidthChangesSurviveReload() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let gaps = (0..<5).map { _ in store.add() }
        for step in 0..<400 {
            store.setWidth(4 + (step * 7) % 397, for: gaps[step % 5].id)
        }
        #expect(GapStore(defaults: defaults).gaps == store.gaps)
        #expect(store.gaps.map(\.id) == gaps.map(\.id))
    }

    @Test func setNamePersists() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let gap = store.add()
        store.setName("Jobb", for: gap.id)
        #expect(GapStore(defaults: defaults).gaps.first?.name == "Jobb")
    }

    @Test func setStylePersists() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let gap = store.add()
        store.setStyle(.line, for: gap.id)
        #expect(GapStore(defaults: defaults).gaps.first?.style == .line)
    }

    @Test func settingTheSameNameOrStyleDoesNotNotify() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let gap = store.add()
        var changes = 0
        store.onChange = { changes += 1 }
        store.setName("", for: gap.id)
        store.setStyle(.empty, for: gap.id)
        #expect(changes == 0)
        store.setName("Jobb", for: gap.id)
        store.setName("Jobb", for: gap.id)
        store.setStyle(.dot, for: gap.id)
        store.setStyle(.dot, for: gap.id)
        #expect(changes == 2)
    }

    @Test func setNameForUnknownIdDoesNothing() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let gap = store.add()
        var changes = 0
        store.onChange = { changes += 1 }
        store.setName("Jobb", for: UUID())
        store.setStyle(.line, for: UUID())
        #expect(store.gaps == [gap])
        #expect(changes == 0)
    }

    @Test func storedListFromTheFirstVersionIsKept() {
        defer { temporary.remove() }
        let first = UUID(), second = UUID()
        let json = #"[{"id":"\#(first.uuidString)","width":24},{"id":"\#(second.uuidString)","width":80}]"#
        defaults.set(Data(json.utf8), forKey: GapStore.storageKey)
        let gaps = GapStore(defaults: defaults).gaps
        #expect(gaps.map(\.id) == [first, second])
        #expect(gaps.map(\.width) == [24, 80])
        #expect(gaps.allSatisfy { $0.style == .empty && $0.name == "" })
    }

    @Test func addWritesPositionRightmost() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let first = store.add()
        #expect(defaults.double(forKey: positionKey(first)) == 1)
        let second = store.add()
        #expect(defaults.double(forKey: positionKey(second)) == 0.5)
    }

    @Test func addLeftOfWritesPositionJustLeft() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let neighbour = store.add()
        defaults.set(147.0, forKey: positionKey(neighbour))
        let left = store.add(leftOf: neighbour.id)
        #expect(defaults.double(forKey: positionKey(left)) == 148)
        let between = store.add(leftOf: neighbour.id)
        #expect(defaults.double(forKey: positionKey(between)) == 147.5)
    }

    @Test func addLeftOfUnknownIdFallsBackToRightmost() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let gap = store.add(leftOf: UUID())
        #expect(defaults.double(forKey: positionKey(gap)) == 1)
    }

    @Test func addLeftOfNeighbourWithoutPositionFallsBackToRightmost() {
        defer { temporary.remove() }
        let store = GapStore(defaults: defaults)
        let neighbour = store.add()
        defaults.removeObject(forKey: positionKey(neighbour))
        let gap = store.add(leftOf: neighbour.id)
        #expect(defaults.double(forKey: positionKey(gap)) == 1)
    }
}
