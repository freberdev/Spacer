import Foundation
import Testing
@testable import SpacerCore

@Suite struct GapNameAndStyleTests {
    @Test func newGapsAreEmptyAndUnnamed() {
        let gap = Gap()
        #expect(gap.name == "")
        #expect(gap.style == .empty)
        #expect(gap.visibleText == nil)
    }

    @Test func decodingDataFromTheFirstVersion() throws {
        let id = UUID()
        let gap = try JSONDecoder().decode(Gap.self, from: Data(#"{"id":"\#(id.uuidString)","width":60}"#.utf8))
        #expect(gap.id == id)
        #expect(gap.width == 60)
        #expect(gap.name == "")
        #expect(gap.style == .empty)
    }

    @Test func decodingAnUnknownStyleGivesEmpty() throws {
        let json = #"{"id":"\#(UUID().uuidString)","width":60,"name":"Work","style":"sparkles"}"#
        let gap = try JSONDecoder().decode(Gap.self, from: Data(json.utf8))
        #expect(gap.style == .empty)
        #expect(gap.name == "Work")
    }

    @Test func decodingCleansTheName() throws {
        let long = String(repeating: "x", count: 80)
        let json = #"{"id":"\#(UUID().uuidString)","width":60,"name":"\#(long)","style":"name"}"#
        let gap = try JSONDecoder().decode(Gap.self, from: Data(json.utf8))
        #expect(gap.name.count == 30)
    }

    @Test func nameIsOneLine() {
        var gap = Gap()
        gap.setName("Jobb\nmöten")
        #expect(gap.name == "Jobb möten")
        gap.setName("a\r\nb\tc")
        #expect(gap.name == "a b c")
    }

    @Test func nameIsCutAtThirtyCharacters() {
        var gap = Gap()
        gap.setName(String(repeating: "å", count: 40))
        #expect(gap.name == String(repeating: "å", count: 30))
        gap.setName(String(repeating: "👍🏽", count: 40))
        #expect(gap.name == String(repeating: "👍🏽", count: 30))
    }

    @Test func nameIsKeptAsTyped() {
        var gap = Gap()
        gap.setName("Jobb ")
        #expect(gap.name == "Jobb ")
    }

    @Test func displayNameIsTrimmed() {
        var gap = Gap()
        gap.setName("  Jobb ")
        #expect(gap.displayName == "Jobb")
        gap.setName("   ")
        #expect(gap.displayName == "")
    }

    @Test func visibleTextNeedsTheNameStyleAndAName() {
        var gap = Gap()
        gap.setName("Jobb")
        for style in [GapStyle.empty, .line, .dot] {
            gap.style = style
            #expect(gap.visibleText == nil)
        }
        gap.style = .name
        #expect(gap.visibleText == "Jobb")
        gap.setName("   ")
        #expect(gap.visibleText == nil)
        gap.setName("")
        #expect(gap.visibleText == nil)
    }

    @Test func visibleTextIsTrimmed() {
        var gap = Gap(style: .name)
        gap.setName(" Jobb ")
        #expect(gap.visibleText == "Jobb")
    }

    @Test func aGapIsAsWideAsItsWidthWhenItShowsNoText() {
        #expect(Gap(width: 24).length(textWidth: nil) == 24)
        #expect(Gap(width: 4).length(textWidth: nil) == 4)
    }

    @Test func aGapGrowsToFitItsText() {
        #expect(Gap(width: 4).length(textWidth: 30.2) == 31)
        #expect(Gap(width: 24).length(textWidth: 24.0) == 24)
    }

    @Test func aWideGapKeepsItsWidthAroundAShortText() {
        #expect(Gap(width: 60).length(textWidth: 30.2) == 60)
    }

    @Test func aTextWidthThatIsNotANumberIsIgnored() {
        #expect(Gap(width: 24).length(textWidth: .nan) == 24)
        #expect(Gap(width: 24).length(textWidth: -5) == 24)
        #expect(Gap(width: 24).length(textWidth: .infinity) == 24)
    }

    @Test func nameAndStyleSurviveTheRoundTrip() throws {
        var gap = Gap(width: 80)
        gap.setName("🎧 Ljud")
        gap.style = .name
        let copy = try JSONDecoder().decode(Gap.self, from: JSONEncoder().encode(gap))
        #expect(copy == gap)
    }

    @Test func everyStyleHasItsOwnStoredName() {
        #expect(GapStyle.allCases.map(\.rawValue) == ["empty", "line", "dot", "name"])
    }
}
