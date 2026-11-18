import Foundation

/// A settings domain of its own for one test, removed again by `remove()`.
struct TemporaryDefaults {
    let name = "com.freberdev.spacer.tests." + UUID().uuidString
    let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: name)!
    }

    func remove() {
        defaults.removePersistentDomain(forName: name)
    }
}
