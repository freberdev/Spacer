import Foundation
import Testing
@testable import SpacerCore

@Suite struct GapOrderTests {
    let a = Gap(), b = Gap(), c = Gap()

    @Test func sortsByPosition() {
        let ordered = GapOrder.leftToRight([a, b, c], positions: [a.id: 300, b.id: 100, c.id: 200])
        #expect(ordered == [b, c, a])
    }

    @Test func gapsWithoutPositionComeLastInCreationOrder() {
        let ordered = GapOrder.leftToRight([a, b, c], positions: [c.id: 50])
        #expect(ordered == [c, a, b])
    }

    @Test func equalPositionsKeepCreationOrder() {
        let ordered = GapOrder.leftToRight([a, b, c], positions: [a.id: 70, b.id: 70, c.id: 70])
        #expect(ordered == [a, b, c])
        let mixed = GapOrder.leftToRight([c, b, a], positions: [a.id: 70, b.id: 10, c.id: 70])
        #expect(mixed == [b, c, a])
    }

    @Test func emptyInputGivesEmptyOutput() {
        #expect(GapOrder.leftToRight([], positions: [:]).isEmpty)
        #expect(GapOrder.leftToRight([], positions: [a.id: 1]).isEmpty)
    }

    @Test func positionsForUnknownIdsAreIgnored() {
        let ordered = GapOrder.leftToRight([a, b], positions: [UUID(): 5, b.id: 9])
        #expect(ordered == [b, a])
    }

    @Test func positionsThatAreNotNumbersCountAsMissing() {
        let ordered = GapOrder.leftToRight([a, b, c], positions: [a.id: .nan, b.id: 20, c.id: 10])
        #expect(ordered == [c, b, a])
    }
}
