import AppKit
import BarKit
import SwiftUI

/// A click-through window laid over the menu bar beside the chevron, playing `DragDemo`.
@MainActor
final class DragDemoOverlay {
    private enum Metric {
        static let width: CGFloat = 340
        static let captionHeight: CGFloat = 64
        /// Room right of the chevron for where the icon starts.
        static let trailingRoom: CGFloat = 56
        static let fadeOut: TimeInterval = 0.2
        static let stillDuration: TimeInterval = 6
    }

    private var panel: NSPanel?
    private var closeTimer: Timer?
    private var onClose: (() -> Void)?

    var isShowing: Bool { panel != nil }

    /// `chevron` is the chevron's frame on screen; `appearance` the menu bar's.
    func show(beside chevron: NSRect, appearance: NSAppearance, onClose: @escaping () -> Void) {
        guard panel == nil, let screen = MenuBar.screen(at: NSPoint(x: chevron.midX, y: chevron.midY)) else { return }
        self.onClose = onClose
        let animated = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let barHeight = chevron.height
        let height = barHeight + Metric.captionHeight
        let maxX = min(chevron.maxX + Metric.trailingRoom, screen.frame.maxX)
        let frame = NSRect(x: maxX - Metric.width, y: screen.frame.maxY - height, width: Metric.width, height: height)

        let panel = NSPanel(
            contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        // Just above the status items, so the stand-in icon passes over the real ones.
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        // Drawn in the menu bar's own appearance, so the stand-in icon matches the real ones.
        panel.appearance = appearance
        panel.contentView = NSHostingView(
            rootView: DragDemoView(
                start: Date(), chevronX: chevron.midX - frame.minX, barHeight: barHeight, animated: animated))
        panel.orderFrontRegardless()
        self.panel = panel

        let duration = animated ? DragDemo.duration : Metric.stillDuration
        closeTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        }
    }

    func close() {
        guard let panel else { return }
        self.panel = nil
        closeTimer?.invalidate()
        closeTimer = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Metric.fadeOut
            panel.animator().alphaValue = 0
        } completionHandler: {
            MainActor.assumeIsolated { panel.orderOut(nil) }
        }
        onClose?()
        onClose = nil
    }
}
