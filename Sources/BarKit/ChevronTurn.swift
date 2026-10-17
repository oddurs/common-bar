import Foundation

/// The chevron's half turn as the bar opens and closes: it eases out past the end by a
/// touch and settles back, over about as long as macOS takes to glide the icons in. A pure
/// function of time, so the renderer only draws the angle it is given.
public struct ChevronTurn: Sendable {
    public static let duration: TimeInterval = 0.4
    /// How far past the end the turn swings before settling; larger is bouncier.
    static let overshoot = 1.2

    public let from: Double
    public let to: Double

    public init(from: Double, to: Double) {
        self.from = from
        self.to = to
    }

    /// The angle `elapsed` seconds in, and whether the turn has finished.
    public func angle(at elapsed: TimeInterval) -> (angle: Double, finished: Bool) {
        let t = min(max(elapsed / Self.duration, 0), 1)
        return (from + (to - from) * Self.easeOutBack(t), t >= 1)
    }

    static func easeOutBack(_ t: Double) -> Double {
        // Exact at the ends, so a finished turn rests precisely where it was aimed.
        if t <= 0 { return 0 }
        if t >= 1 { return 1 }
        let c = overshoot
        return 1 + (c + 1) * pow(t - 1, 3) + c * pow(t - 1, 2)
    }
}
