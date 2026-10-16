import Foundation

/// The how-to played in the menu bar: hold ⌘, pick up an icon right of the chevron,
/// drag it past the chevron, let go, and watch it hide. A pure function of time, so it
/// plays the same every run and the renderer only draws what it is given.
public enum DragDemo {
    /// One pass, in seconds.
    public static let loop: TimeInterval = 3.2
    public static let passes = 3
    public static var duration: TimeInterval { loop * Double(passes) }

    /// Seconds into a pass when each beat starts.
    enum Beat {
        static let appear: TimeInterval = 0
        static let commandDown: TimeInterval = 0.4
        static let pickUp: TimeInterval = 0.7
        static let dragStart: TimeInterval = 0.9
        static let drop: TimeInterval = 1.9
        static let hide: TimeInterval = 2.1
        static let commandUp: TimeInterval = 2.6
        static let fadeIn: TimeInterval = 0.25
        static let liftTime: TimeInterval = 0.15
        static let hideTime: TimeInterval = 0.4
    }

    public struct Frame: Equatable, Sendable {
        /// ⌘ is held.
        public var commandDown: Bool
        /// 0 where the icon starts, right of the chevron; 1 where it is dropped, left of it.
        public var progress: Double
        /// 0 resting, 1 picked up.
        public var lift: Double
        public var iconOpacity: Double
        public var showsCursor: Bool
        public var isFinished: Bool
    }

    public static func frame(at elapsed: TimeInterval) -> Frame {
        guard elapsed < duration else {
            return Frame(commandDown: false, progress: 1, lift: 0, iconOpacity: 0, showsCursor: false, isFinished: true)
        }
        let t = max(0, elapsed).truncatingRemainder(dividingBy: loop)
        let commandDown = t >= Beat.commandDown && t < Beat.commandUp
        let progress = easeInOut(ramp(t, from: Beat.dragStart, to: Beat.drop))
        let lift =
            ramp(t, from: Beat.pickUp, to: Beat.pickUp + Beat.liftTime)
            - ramp(t, from: Beat.drop, to: Beat.drop + Beat.liftTime)
        let opacity =
            ramp(t, from: Beat.appear, to: Beat.appear + Beat.fadeIn)
            - ramp(t, from: Beat.hide, to: Beat.hide + Beat.hideTime)
        let showsCursor = t >= Beat.pickUp && t < Beat.hide
        return Frame(
            commandDown: commandDown, progress: progress, lift: lift, iconOpacity: opacity,
            showsCursor: showsCursor, isFinished: false)
    }

    /// 0 before `start`, 1 after `end`, linear between.
    static func ramp(_ t: TimeInterval, from start: TimeInterval, to end: TimeInterval) -> Double {
        min(1, max(0, (t - start) / (end - start)))
    }

    static func easeInOut(_ x: Double) -> Double {
        x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
    }
}
