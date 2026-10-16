import Foundation

/// Resting the pointer on empty menu bar space reveals the hidden items; they hide
/// again once the pointer has been out of the bar for a moment.
public struct Hover: Sendable {
    public static let delay: TimeInterval = 0.25
    public static let exitDelay: TimeInterval = 0.5

    public enum Action: Equatable, Sendable {
        case none
        case reveal
        case collapse
    }

    /// The current reveal came from hovering, so leaving the bar should undo it.
    public private(set) var revealed = false
    /// Hover may reveal. A deliberate toggle disarms it until the pointer leaves the bar.
    public private(set) var armed = true
    private var since: Date?
    private var exitSince: Date?

    public init() {}

    /// A click, scroll, or timer changed the collapsed state.
    public mutating func toggled() {
        revealed = false
        armed = false
    }

    /// The pointer left the bar with nothing revealed by hover.
    public mutating func rearm() {
        armed = true
    }

    /// Advances the state by one poll. `idle` means no modifier or mouse button is held.
    /// `menuOpen` is only evaluated while a hover reveal waits to close, because it asks
    /// the window server.
    public mutating func update(
        isCollapsed: Bool, overEmptySpace: Bool, inMenuBar: Bool, idle: Bool, enabled: Bool,
        menuOpen: @autoclosure () -> Bool, now: Date
    ) -> Action {
        var action = Action.none
        if !overEmptySpace { since = nil }

        if isCollapsed && overEmptySpace && armed && idle && enabled {
            let start = since ?? now
            since = start
            if now.timeIntervalSince(start) >= Self.delay {
                revealed = true
                since = nil
                action = .reveal
            }
        }

        guard revealed else { return action }
        // Stay open while the pointer is in the bar or in a menu opened from it.
        if inMenuBar || !idle || menuOpen() {
            exitSince = nil
            return action
        }
        let start = exitSince ?? now
        exitSince = start
        if now.timeIntervalSince(start) >= Self.exitDelay {
            exitSince = nil
            return .collapse
        }
        return action
    }
}
