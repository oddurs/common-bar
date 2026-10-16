// Renders Resources/AppIcon.icns and docs/icon.png. Run: swift scripts/make-icon.swift
import AppKit

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: 1024, height: 1024)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Apple's icon grid: an 824 pt body centred on a 1024 pt canvas.
    let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
    NSShadow().then {
        $0.shadowBlurRadius = 20; $0.shadowOffset = NSSize(width: 0, height: -10);
        $0.shadowColor = .black.withAlphaComponent(0.3); $0.set()
    }
    NSGradient(colors: [NSColor(white: 0.24, alpha: 1), NSColor(white: 0.09, alpha: 1)])!.draw(in: shape, angle: -90)
    NSShadow().set()

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    // A menu bar strip: items fading out left of the divider, the chevron, then visible items.
    let strip = NSRect(x: 160, y: 412, width: 704, height: 200)
    NSColor.white.withAlphaComponent(0.1).setFill()
    NSBezierPath(roundedRect: strip, xRadius: 100, yRadius: 100).fill()

    func dot(_ x: CGFloat, _ alpha: CGFloat) {
        NSColor.white.withAlphaComponent(alpha).setFill()
        NSBezierPath(ovalIn: NSRect(x: x - 34, y: strip.midY - 34, width: 68, height: 68)).fill()
    }
    dot(262, 0.14)
    dot(372, 0.3)

    NSColor.white.withAlphaComponent(0.9).setFill()
    NSBezierPath(roundedRect: NSRect(x: 450, y: strip.midY - 62, width: 14, height: 124), xRadius: 7, yRadius: 7).fill()

    let chevron = NSBezierPath()
    chevron.move(to: NSPoint(x: 582, y: strip.midY + 54))
    chevron.line(to: NSPoint(x: 534, y: strip.midY))
    chevron.line(to: NSPoint(x: 582, y: strip.midY - 54))
    chevron.lineWidth = 28
    chevron.lineCapStyle = .round
    chevron.lineJoinStyle = .round
    NSColor.white.setStroke()
    chevron.stroke()

    dot(672, 1)
    dot(772, 1)
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

extension NSShadow { func then(_ f: (NSShadow) -> Void) { f(self) } }

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
if FileManager.default.fileExists(atPath: iconset.path) { try FileManager.default.removeItem(at: iconset) }
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    try render(size).write(to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try render(size * 2).write(to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
try render(256).write(to: root.appendingPathComponent("docs/icon.png"))
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Resources/AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
exit(iconutil.terminationStatus)
