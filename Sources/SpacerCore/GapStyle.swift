import Foundation

/// What a gap shows in the menu bar.
public enum GapStyle: String, Codable, CaseIterable, Sendable {
    /// Nothing: plain empty space.
    case empty
    /// A thin vertical line.
    case line
    /// A small dot.
    case dot
    /// The gap's name, as text.
    case name
}
