import Foundation
import Testing
@testable import SpacerCore

@MainActor @Suite struct PreferencesTests {
    let temporary = TemporaryDefaults()

    @Test func flagsDefaultToFalseAndPersist() {
        defer { temporary.remove() }
        let preferences = Preferences(defaults: temporary.defaults)
        #expect(preferences.didShowWelcome == false)
        #expect(preferences.didRequestLoginItem == false)
        preferences.didShowWelcome = true
        #expect(Preferences(defaults: temporary.defaults).didShowWelcome == true)
        #expect(Preferences(defaults: temporary.defaults).didRequestLoginItem == false)
        preferences.didRequestLoginItem = true
        #expect(Preferences(defaults: temporary.defaults).didRequestLoginItem == true)
    }
}
