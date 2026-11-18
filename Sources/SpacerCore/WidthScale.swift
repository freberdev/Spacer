import Foundation

/// How a width slider maps to widths. The scale is finer at the narrow end, where a point
/// more or less is easy to see, and coarser at the wide end.
public enum WidthScale {
    private static let range = Double(Gap.maxWidth - Gap.minWidth)

    /// The width at `fraction` of the way along the slider, from 0 to 1.
    public static func width(at fraction: Double) -> Int {
        guard !fraction.isNaN else { return Gap.minWidth }
        let t = min(max(fraction, 0), 1)
        return Gap.clamped(Double(Gap.minWidth) + range * t * t)
    }

    /// Where along the slider, from 0 to 1, the width lies.
    public static func fraction(for width: Int) -> Double {
        (Double(Gap.clamped(width) - Gap.minWidth) / range).squareRoot()
    }
}
