import Foundation

/// Things the app remembers about its first runs.
@MainActor
public final class Preferences {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// The settings window has been shown once, on the first run.
    public var didShowWelcome: Bool {
        get { defaults.bool(forKey: "didShowWelcome") }
        set { defaults.set(newValue, forKey: "didShowWelcome") }
    }

    /// Opening at login has been turned on once, the first time the app ran from Applications.
    public var didRequestLoginItem: Bool {
        get { defaults.bool(forKey: "didRequestLoginItem") }
        set { defaults.set(newValue, forKey: "didRequestLoginItem") }
    }
}
