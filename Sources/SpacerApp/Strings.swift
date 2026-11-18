import Foundation

/// Looks up a user-facing string by key in the app's Localizable.strings.
func L(_ key: String) -> String {
    NSLocalizedString(key, bundle: .main, comment: "")
}

/// Looks up a format string by key and fills in the arguments.
func L(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: L(key), locale: .current, arguments: arguments)
}
