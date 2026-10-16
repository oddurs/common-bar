import Foundation

/// Holding ⌘ alone over the menu bar reveals the hidden items for ⌘-dragging.
public struct Peek: Sendable {
    /// Keeps ⌘-Tab and shortcuts from flashing the bar.
    public static let delay: TimeInterval = 0.2

    public private(set) var isPeeking = false
    private var commandHeldSince: Date?

    public init() {}

    /// Advances the state by one poll. Returns whether `isPeeking` changed.
    public mutating func update(commandOnly: Bool, inMenuBar: Bool, mouseDown: Bool, now: Date) -> Bool {
        if isPeeking {
            // Ending mid-drag would yank the item out from under the cursor.
            if !commandOnly && !mouseDown {
                isPeeking = false
                return true
            }
        } else if commandOnly && inMenuBar && !mouseDown {
            let since = commandHeldSince ?? now
            commandHeldSince = since
            if now.timeIntervalSince(since) >= Self.delay {
                isPeeking = true
                commandHeldSince = nil
                return true
            }
        } else {
            commandHeldSince = nil
        }
        return false
    }
}
