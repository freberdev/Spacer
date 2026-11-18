import Foundation
import Testing
@testable import SpacerCore

@Suite struct GapTests {
    @Test func defaultWidthIs24() {
        #expect(Gap().width == 24)
    }

    @Test func clampsIntegers() {
        #expect(Gap.clamped(0) == 4)
        #expect(Gap.clamped(-5) == 4)
        #expect(Gap.clamped(4) == 4)
        #expect(Gap.clamped(400) == 400)
        #expect(Gap.clamped(401) == 400)
        #expect(Gap.clamped(10_000) == 400)
    }

    @Test func clampsAndRoundsDoubles() {
        #expect(Gap.clamped(23.6) == 24)
        #expect(Gap.clamped(3.2) == 4)
        #expect(Gap.clamped(Double.nan) == 4)
        #expect(Gap.clamped(Double.infinity) == 400)
        #expect(Gap.clamped(-Double.infinity) == 4)
    }

    @Test func initClamps() {
        #expect(Gap(width: 9999).width == 400)
        #expect(Gap(width: -1).width == 4)
    }

    @Test func setWidthClamps() {
        var gap = Gap()
        gap.setWidth(9999)
        #expect(gap.width == 400)
        gap.setWidth(80)
        #expect(gap.width == 80)
    }

    @Test func decodingClamps() throws {
        let id = UUID()
        let wide = try JSONDecoder().decode(Gap.self, from: Data(#"{"id":"\#(id.uuidString)","width":9999}"#.utf8))
        #expect(wide.width == 400)
        #expect(wide.id == id)
        let narrow = try JSONDecoder().decode(Gap.self, from: Data(#"{"id":"\#(id.uuidString)","width":0}"#.utf8))
        #expect(narrow.width == 4)
    }

    @Test func encodingRoundTrips() throws {
        let gap = Gap(width: 80)
        let copy = try JSONDecoder().decode(Gap.self, from: JSONEncoder().encode(gap))
        #expect(copy == gap)
    }

    @Test func autosaveNameIsStableAndLowercase() {
        let id = UUID(uuidString: "6F9619FF-8B86-D011-B42D-00C04FC964FF")!
        #expect(Gap(id: id).autosaveName == "gap-6f9619ff-8b86-d011-b42d-00c04fc964ff")
        #expect(Gap(id: id).autosaveName == Gap(id: id, width: 80).autosaveName)
    }
}
