import Testing
@testable import SpacerCore

@Suite struct WidthScaleTests {
    @Test func endsOfTheSliderAreTheLimits() {
        #expect(WidthScale.width(at: 0) == 4)
        #expect(WidthScale.width(at: 1) == 400)
    }

    @Test func theNarrowEndIsFiner() {
        // Halfway along the slider is a quarter of the way through the widths.
        #expect(WidthScale.width(at: 0.5) == 103)
        #expect(WidthScale.width(at: 0.25) < 30)
    }

    @Test func widthNeverDecreasesAlongTheSlider() {
        let widths = stride(from: 0.0, through: 1.0, by: 0.001).map(WidthScale.width(at:))
        #expect(widths == widths.sorted())
    }

    @Test func everyWidthSurvivesTheRoundTrip() {
        for width in Gap.minWidth...Gap.maxWidth {
            #expect(WidthScale.width(at: WidthScale.fraction(for: width)) == width)
        }
    }

    @Test func fractionsOutsideTheSliderAreClamped() {
        #expect(WidthScale.width(at: -1) == 4)
        #expect(WidthScale.width(at: 7) == 400)
        #expect(WidthScale.width(at: .nan) == 4)
        #expect(WidthScale.width(at: .infinity) == 400)
    }

    @Test func widthsOutsideTheLimitsAreClamped() {
        #expect(WidthScale.fraction(for: 0) == 0)
        #expect(WidthScale.fraction(for: 9999) == 1)
    }
}
