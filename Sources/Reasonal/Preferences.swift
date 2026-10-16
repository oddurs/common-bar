import BarKit
import Foundation

enum Preferences {
    static let showOnHover = "showOnHover"
    static let showOnScroll = "showOnScroll"
    static let showOnClick = "showOnClick"
    static let autoHide = "autoHide"
    static let alwaysHiddenSection = "alwaysHiddenSection"

    static func register() {
        UserDefaults.standard.register(defaults: [
            showOnHover: true,
            showOnScroll: true,
            showOnClick: true,
            autoHide: AutoHide.standard.rawValue,
            alwaysHiddenSection: false,
        ])
    }

    static func isOn(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static var autoHideDelay: AutoHide {
        AutoHide(stored: UserDefaults.standard.object(forKey: autoHide))
    }
}
