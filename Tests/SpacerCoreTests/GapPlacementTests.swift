import Testing
@testable import SpacerCore

@Suite struct GapPlacementTests {
    @Test func keyUsesTheSystemPrefix() {
        #expect(GapPlacement.key(for: "gap-abc") == "NSStatusItem Preferred Position gap-abc")
    }

    @Test func leftOfAddsOne() {
        #expect(GapPlacement.position(leftOf: 10, others: [10]) == 11)
    }

    @Test func leftOfSqueezesBetweenCloseNeighbours() {
        #expect(GapPlacement.position(leftOf: 1, others: [1, 2]) == 1.5)
        #expect(GapPlacement.position(leftOf: 1, others: [1, 1.5, 2]) == 1.25)
    }

    @Test func leftOfIgnoresDistantNeighbours() {
        #expect(GapPlacement.position(leftOf: 1, others: [1, 40]) == 2)
    }

    @Test func leftOfIgnoresNeighboursToTheRight() {
        #expect(GapPlacement.position(leftOf: 10, others: [9.5, 10]) == 11)
    }

    @Test func rightmostIsOneWhenFree() {
        #expect(GapPlacement.rightmost(others: []) == 1)
        #expect(GapPlacement.rightmost(others: [5, 9]) == 1)
    }

    @Test func rightmostHalvesWhenTaken() {
        #expect(GapPlacement.rightmost(others: [1, 3]) == 0.5)
        #expect(GapPlacement.rightmost(others: [0.5, 1]) == 0.25)
    }

    @Test func rightmostNeverGoesBelowTheFloor() {
        var others: [Double] = []
        for _ in 0..<200 { others.append(GapPlacement.rightmost(others: others)) }
        #expect(others.allSatisfy { $0 >= GapPlacement.smallestPosition })
        #expect(GapPlacement.smallestPosition > 0)
    }

    @Test func rightmostIgnoresPositionsThatAreNotPositive() {
        #expect(GapPlacement.rightmost(others: [0, -3]) == 1)
    }
}
