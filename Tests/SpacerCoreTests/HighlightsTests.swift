import Foundation
import Testing
@testable import SpacerCore

@Suite struct HighlightsTests {
    let a = UUID(), b = UUID()

    @Test func nothingIsHighlightedAtFirst() {
        #expect(Highlights().isHighlighted(a) == false)
    }

    @Test func pointingHighlights() {
        var highlights = Highlights()
        #expect(highlights.setHovered(a, true) == true)
        #expect(highlights.isHighlighted(b) == false)
        #expect(highlights.setHovered(a, false) == false)
    }

    @Test func releasingTheSliderKeepsTheHighlightWhilePointing() {
        var highlights = Highlights()
        highlights.setHovered(a, true)
        highlights.setEditing(a, true)
        #expect(highlights.setEditing(a, false) == true)
    }

    @Test func leavingTheRowKeepsTheHighlightWhileDragging() {
        var highlights = Highlights()
        highlights.setHovered(a, true)
        highlights.setEditing(a, true)
        #expect(highlights.setHovered(a, false) == true)
        #expect(highlights.setEditing(a, false) == false)
    }

    @Test func clearReturnsWhatWasHighlighted() {
        var highlights = Highlights()
        highlights.setHovered(a, true)
        highlights.setEditing(b, true)
        #expect(highlights.clear() == [a, b])
        #expect(highlights.isHighlighted(a) == false)
        #expect(highlights.isHighlighted(b) == false)
        #expect(highlights.clear().isEmpty)
    }
}
