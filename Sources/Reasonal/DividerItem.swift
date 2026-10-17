import AppKit
import BarKit

/// A divider status item that is stretched, taken down to nothing, or shown as a slim
/// marker, without ever being removed or hidden with `isVisible`. On Tahoe either of those
/// is how the system records a user taking an item out of the menu bar: it writes
/// `VisibleCC = 0` and forgets the item's saved position. The technique is the one Ice and
/// Thaw use.
@MainActor
final class DividerItem {
    private enum Metric {
        /// A zero-length item can stay a synthetic window with no window-server window; one
        /// point makes a real one before the intended length is applied.
        static let creationLength: CGFloat = 1
        /// The width left when taken down to nothing. Zero would let the window vanish.
        static let collapsedWidth: CGFloat = 1
        static let markerWidth: CGFloat = 4
        /// What macOS adds to an item's length while its padding constraint is on, measured on Tahoe.
        static let padding: CGFloat = 16
        static let markerFade: TimeInterval = 0.15
    }

    let item: NSStatusItem
    private let marker: NSImage
    /// Holds the button's width to macOS's padding. With it off, the item can be narrower
    /// than an empty item, which is what leaves no gap.
    private let paddingConstraint: NSLayoutConstraint?
    private var state: DividerState?

    init(named name: String, marker: NSImage) {
        DividerItem.markVisible(name)
        item = NSStatusBar.system.statusItem(withLength: Metric.creationLength)
        item.autosaveName = name
        self.marker = marker
        if let button = item.button, let content = button.window?.contentView {
            let container = button.superview
            paddingConstraint = content.constraintsAffectingLayout(for: .horizontal)
                .first { $0.secondItem === container }
            button.isEnabled = false
            button.appearsDisabled = true
            button.imagePosition = .imageOnly
            button.setAccessibilityElement(false)
        } else {
            paddingConstraint = nil
        }
    }

    /// Seeds the item as shown, before it is created, so a missing key can't start it hidden.
    static func markVisible(_ name: String) {
        let defaults = UserDefaults.standard
        for key in ["NSStatusItem Visible \(name)", "NSStatusItem VisibleCC \(name)"]
        where defaults.object(forKey: key) == nil {
            defaults.set(true, forKey: key)
        }
    }

    /// Writes only what changed: every status item update on Tahoe is a Control Center
    /// round trip, and repeating them leaks system resources.
    func set(_ newState: DividerState, animated: Bool) {
        guard newState != state, let button = item.button else { return }
        state = newState
        setIfChanged(button, \.isHighlighted, false)
        switch newState {
        case .stretched:
            // Measured before stretching, while the item still sits where it ends.
            let length = reach
            setIfChanged(button, \.image, nil)
            setIfChanged(button, \.alphaValue, 0)
            paddingConstraint?.isActive = true
            setIfChanged(item, \.length, length)
        case .collapsed:
            setIfChanged(button, \.alphaValue, 0)
            paddingConstraint?.isActive = false
            setIfChanged(item, \.length, 0)
            setWindowWidth(Metric.collapsedWidth)
        case .marker:
            setIfChanged(button, \.image, marker)
            paddingConstraint?.isActive = false
            setIfChanged(item, \.length, Metric.markerWidth)
            setWindowWidth(Metric.markerWidth)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = animated ? Metric.markerFade : 0
                button.animator().alphaValue = 1
            }
        }
    }

    /// See `DividerLayout.reach`. The full stretch until AppKit's frame for the item agrees
    /// with where the window server has it.
    private var reach: CGFloat {
        guard let window = item.button?.window, let screen = window.screen,
            MenuBar.hasStatusItem(at: window.frame, on: screen)
        else { return DividerLayout.stretchedLength }
        return DividerLayout.reach(
            dividerEnd: window.frame.maxX, screenMinX: screen.frame.minX, padding: Metric.padding)
    }

    private func setWindowWidth(_ width: CGFloat) {
        guard let window = item.button?.window, window.frame.width != width else { return }
        window.setContentSize(NSSize(width: width, height: window.frame.height))
    }

    private func setIfChanged<Root: AnyObject, Value: Equatable>(
        _ root: Root, _ keyPath: ReferenceWritableKeyPath<Root, Value>, _ value: Value
    ) {
        if root[keyPath: keyPath] != value { root[keyPath: keyPath] = value }
    }
}
