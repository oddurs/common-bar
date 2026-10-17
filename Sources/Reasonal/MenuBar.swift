import AppKit
import BarKit

/// Where things are in the menu bar. Points are global Cocoa coordinates. The window
/// server reports top-left-origin frames, so its windows are matched by x and by the
/// top edge of the screen they sit on.
enum MenuBar {
    static func screen(at p: NSPoint) -> NSScreen? {
        NSScreen.screens.first {
            ($0.frame.minX...$0.frame.maxX).contains(p.x) && ($0.frame.minY...$0.frame.maxY).contains(p.y)
        }
    }

    static func contains(_ p: NSPoint) -> Bool {
        guard let screen = screen(at: p) else { return false }
        return p.y >= screen.frame.maxY - height(of: screen)
    }

    /// Part of the bar holding neither the app's menus nor a status item. `ignoring`
    /// names the caller's own items, whose stretched divider would otherwise cover the gap.
    static func isEmptySpace(_ p: NSPoint, ignoring names: Set<String>) -> Bool {
        guard let screen = screen(at: p), contains(p) else { return false }
        // App menus run from the left; on a notched display they stop at the notch.
        let start = screen.auxiliaryTopRightArea.map { screen.frame.minX + $0.minX } ?? screen.frame.midX
        guard p.x >= start else { return false }
        let top = topInWindowServer(of: screen)
        return !windows(onScreenOnly: true).contains { window in
            window.layer == statusLayer && !names.contains(window.name)
                && abs(window.frame.minY - top) < 1 && (window.frame.minX...window.frame.maxX).contains(p.x)
        }
    }

    /// Whether the window server has a status item at `frame` (Cocoa coordinates) on `screen`.
    static func hasStatusItem(at frame: NSRect, on screen: NSScreen) -> Bool {
        let top = topInWindowServer(of: screen)
        return windows(onScreenOnly: false).contains {
            $0.layer == statusLayer && abs($0.frame.minY - top) < 1
                && abs($0.frame.minX - frame.minX) < 1 && abs($0.frame.width - frame.width) < 1
        }
    }

    /// A menu or popover from any menu bar item is showing.
    static var isMenuOpen: Bool {
        windows(onScreenOnly: true).contains { $0.layer > statusLayer && $0.layer < dragLayer }
    }

    private static let statusLayer = Int(CGWindowLevelForKey(.statusWindow))
    private static let dragLayer = Int(CGWindowLevelForKey(.draggingWindow))

    private static func height(of screen: NSScreen) -> CGFloat {
        // visibleFrame excludes the menu bar, which is taller on notched displays.
        max(NSStatusBar.system.thickness, screen.frame.maxY - screen.visibleFrame.maxY)
    }

    private static func topInWindowServer(of screen: NSScreen) -> CGFloat {
        (NSScreen.screens.first?.frame.maxY ?? 0) - screen.frame.maxY
    }

    private struct Window {
        let name: String
        let layer: Int
        let frame: CGRect
    }

    private static func windows(onScreenOnly: Bool) -> [Window] {
        let options: CGWindowListOption = onScreenOnly ? [.optionOnScreenOnly, .excludeDesktopElements] : [.optionAll]
        let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
        return list.compactMap { info in
            guard let layer = info[kCGWindowLayer as String] as? Int,
                let bounds = info[kCGWindowBounds as String] as? NSDictionary,
                let frame = CGRect(dictionaryRepresentation: bounds)
            else { return nil }
            return Window(name: info[kCGWindowName as String] as? String ?? "", layer: layer, frame: frame)
        }
    }
}
