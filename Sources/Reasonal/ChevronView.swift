import AppKit
import BarKit
import QuartzCore

/// The chevron glyph, turned about its own centre as the bar opens and closes.
///
/// AppKit turns a layer-backed view about its layer's anchor, which it keeps at a corner,
/// so a plain rotation swings the glyph off-centre. The turn is instead a single keyframe
/// animation of transforms that each rotate about the centre, sampled from `ChevronTurn`:
/// the render server plays it, rather than the app redrawing the status item every frame,
/// which on Tahoe is a Control Center round trip each time.
@MainActor
final class ChevronView: NSImageView {
    private enum Metric {
        /// Enough samples that straight segments between them read as a smooth curve.
        static let keyframes = 30
    }

    private var angle: Double = 0
    private var turn: (ChevronTurn, start: CFTimeInterval)?

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    /// Turns to `target` radians: 0 points left, π points right.
    func turn(to target: Double, animated: Bool) {
        guard let layer else { return }
        let now = CACurrentMediaTime()
        // Pick up from wherever an unfinished turn has reached.
        let current = turn.map { $0.0.angle(at: now - $0.start).angle } ?? angle
        angle = target
        layer.removeAnimation(forKey: "turn")
        layer.transform = transform(rotatedBy: target, in: layer)

        guard animated, abs(target - current) > 0.001 else {
            turn = nil
            return
        }
        let next = ChevronTurn(from: current, to: target)
        turn = (next, now)
        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.values = (0...Metric.keyframes).map { step in
            let elapsed = ChevronTurn.duration * Double(step) / Double(Metric.keyframes)
            return NSValue(caTransform3D: transform(rotatedBy: next.angle(at: elapsed).angle, in: layer))
        }
        animation.duration = ChevronTurn.duration
        animation.calculationMode = .linear
        layer.add(animation, forKey: "turn")
    }

    /// A rotation about the middle of the view, wherever AppKit has put the layer's anchor.
    private func transform(rotatedBy radians: Double, in layer: CALayer) -> CATransform3D {
        let pivot = CGPoint(
            x: layer.bounds.width * (0.5 - layer.anchorPoint.x),
            y: layer.bounds.height * (0.5 - layer.anchorPoint.y))
        var t = CATransform3DMakeTranslation(pivot.x, pivot.y, 0)
        t = CATransform3DRotate(t, CGFloat(radians), 0, 0, 1)
        return CATransform3DTranslate(t, -pivot.x, -pivot.y, 0)
    }
}
