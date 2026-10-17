import AppKit

/// The app's menu bar marks, drawn rather than taken from SF Symbols so they stay small,
/// thin, and sharp. Template images, so macOS tints them like every other menu bar icon.
/// All sizes are in points.
enum Glyphs {
    enum Chevron {
        static let canvas = NSSize(width: 6, height: 9)
        /// Horizontal and vertical reach of each arm from the tip: equal, so the tip is a right angle.
        static let arm: CGFloat = 3.5
        /// Gap between the tip and the canvas edge: room for the mitred point, and the amount
        /// that puts the chevron's visual centre at the canvas centre, the point it turns about.
        static let tipInset: CGFloat = 1.25
        static let stroke: CGFloat = 1.25
    }

    enum DottedLine {
        static let canvas = NSSize(width: 1.5, height: 12)
        static let dot: CGFloat = 1.5
        /// Distance between the bottoms of neighbouring dots.
        static let pitch: CGFloat = 3
    }

    enum Spacer {
        static let canvas = NSSize(width: 8, height: 14)
        static let corner: CGFloat = 2
        static let stroke: CGFloat = 1
        static let dash: [CGFloat] = [2, 2]
    }

    /// A right-angled chevron pointing left, with a mitred tip and square ends, centred
    /// vertically. Turned half a revolution to point right while the hidden icons show.
    static let chevron: NSImage = {
        let image = NSImage(size: Chevron.canvas, flipped: false) { rect in
            let tipX = rect.minX + Chevron.tipInset
            let endX = tipX + Chevron.arm
            let path = NSBezierPath()
            path.move(to: NSPoint(x: endX, y: rect.midY + Chevron.arm))
            path.line(to: NSPoint(x: tipX, y: rect.midY))
            path.line(to: NSPoint(x: endX, y: rect.midY - Chevron.arm))
            path.lineWidth = Chevron.stroke
            path.lineJoinStyle = .miter
            path.lineCapStyle = .butt
            NSColor.black.setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }()

    enum Line {
        static let canvas = NSSize(width: 1, height: 12)
    }

    /// A hairline, shown only while arranging, marking where hidden icons begin.
    static let line: NSImage = {
        let image = NSImage(size: Line.canvas, flipped: false) { rect in
            NSColor.black.setFill()
            rect.fill()
            return true
        }
        image.isTemplate = true
        return image
    }()

    /// Fine dots, so the always-hidden boundary reads as a mark rather than an icon.
    static let dottedLine: NSImage = {
        let image = NSImage(size: DottedLine.canvas, flipped: false) { rect in
            NSColor.black.setFill()
            for y in stride(from: rect.minY, to: rect.maxY, by: DottedLine.pitch) {
                NSBezierPath(ovalIn: NSRect(x: rect.minX, y: y, width: DottedLine.dot, height: DottedLine.dot)).fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }()

    /// A dashed outline, shown only while arranging so a blank spacer can be found and dragged.
    static let spacer: NSImage = {
        let image = NSImage(size: Spacer.canvas, flipped: false) { rect in
            let inset = rect.insetBy(dx: Spacer.stroke / 2, dy: Spacer.stroke / 2)
            let path = NSBezierPath(roundedRect: inset, xRadius: Spacer.corner, yRadius: Spacer.corner)
            path.lineWidth = Spacer.stroke
            path.setLineDash(Spacer.dash, count: Spacer.dash.count, phase: 0)
            NSColor.black.setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }()
}
