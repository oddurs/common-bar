import Foundation

/// Pulling down on the menu bar reveals; pushing up hides. One gesture acts at most once.
public struct ScrollGesture: Sendable {
    public static let threshold: Double = 6
    /// A pause this long between events starts a new gesture, for wheels that report no phase.
    public static let gap: TimeInterval = 0.3
    /// A wheel reports lines rather than points.
    public static let lineScale: Double = 10

    public enum Intent: Equatable, Sendable {
        case reveal
        case hide
    }

    private var total: Double = 0
    private var handled = false
    private var last: TimeInterval = 0

    public init() {}

    /// Feeds one scroll event. `inverted` is natural scrolling; the delta is read in
    /// finger terms so both settings feel the same.
    public mutating func add(
        deltaY: Double, began: Bool, timestamp: TimeInterval, precise: Bool, inverted: Bool
    ) -> Intent? {
        if began || timestamp - last > Self.gap {
            total = 0
            handled = false
        }
        last = timestamp
        guard !handled else { return nil }

        let delta = inverted ? deltaY : -deltaY
        total += precise ? delta : delta * Self.lineScale
        guard abs(total) >= Self.threshold else { return nil }
        handled = true
        return total < 0 ? .hide : .reveal
    }
}
