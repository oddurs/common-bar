import Foundation

enum Preferences {
    static let showOnHover = "showOnHover"
    static let showOnScroll = "showOnScroll"
    static let showOnClick = "showOnClick"

    static func register() {
        UserDefaults.standard.register(defaults: [
            showOnHover: true,
            showOnScroll: true,
            showOnClick: true,
        ])
    }

    static func isOn(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}
