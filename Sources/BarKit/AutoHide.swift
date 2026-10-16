import Foundation

/// How long a reveal stays open before the hidden items hide again on their own.
public enum AutoHide: Int, CaseIterable, Identifiable, Sendable {
    // Stored as seconds, so a value written by `defaults write` reads back as expected.
    case fiveSeconds = 5
    case tenSeconds = 10
    case thirtySeconds = 30
    case oneMinute = 60
    case never = 0

    public static let standard = AutoHide.tenSeconds

    public var id: Int { rawValue }

    /// Nil when the items stay until hidden by hand.
    public var interval: TimeInterval? {
        self == .never ? nil : TimeInterval(rawValue)
    }

    /// Anything unset or unrecognised falls back to the standard delay rather than
    /// leaving the items open forever.
    public init(stored: Any?) {
        self = (stored as? Int).flatMap(AutoHide.init(rawValue:)) ?? .standard
    }
}
