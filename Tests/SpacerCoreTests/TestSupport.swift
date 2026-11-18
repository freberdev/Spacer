import Foundation
import Testing

/// A settings domain of its own for one test, emptied again by `remove()`.
///
/// The domain is named after the test. macOS leaves an empty file behind for every domain
/// that has been used, and with a fixed name per test there is one such file per test,
/// however many times the tests run.
struct TemporaryDefaults {
    let name: String
    let defaults: UserDefaults

    init() {
        let test = Test.current?.name ?? UUID().uuidString
        name = "com.freberdev.spacer.tests." + test.filter { $0.isLetter || $0.isNumber }
        defaults = UserDefaults(suiteName: name)!
        // A run that was interrupted may have left values behind.
        defaults.removePersistentDomain(forName: name)
    }

    func remove() {
        defaults.removePersistentDomain(forName: name)
    }
}
