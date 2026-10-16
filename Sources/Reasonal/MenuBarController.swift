import AppKit
import ServiceManagement
import SwiftUI
import Symbols

/// Two status items: a chevron that toggles, and a divider to its left.
/// Collapsing stretches the divider so everything left of it is pushed off-screen.
/// Holding ⌘ over the menu bar reveals the divider and the hidden items, so they
/// can be rearranged with the system's own ⌘-drag.
@MainActor
final class MenuBarController: NSObject {
    private enum Metric {
        static let hiddenLength: CGFloat = 10_000
        static let dividerLength: CGFloat = 12
        static let toggleLength: CGFloat = 24
        static let peekDelay: TimeInterval = 0.2
        static let hoverDelay: TimeInterval = 0.25
        static let hoverExitDelay: TimeInterval = 0.5
        static let scrollThreshold: CGFloat = 6
        static let scrollGestureGap: TimeInterval = 0.3
        static let pollInterval: TimeInterval = 1.0 / 30
        static let autoCollapse: TimeInterval = 8
        static let fadeDuration: TimeInterval = 0.12
    }

    private static let onboardedKey = "onboarded"
    private static let itemNames: Set<String> = ["toggle", "divider"]

    private let toggle: NSStatusItem
    private let divider: NSStatusItem
    private let chevron = PassthroughImageView()
    private var chevronSymbol: String?
    private var isCollapsed = true
    private var isPeeking = false
    private var commandHeldSince: Date?
    private var poll: Timer?
    private var collapseTimer: Timer?
    private var eventMonitor: Any?
    private var tipsPopover: NSPopover?

    // Hover
    private var revealedByHover = false
    private var hoverArmed = true
    private var hoverSince: Date?
    private var hoverExitSince: Date?

    // Scroll
    private var scrollTotal: CGFloat = 0
    private var scrollHandled = false
    private var lastScroll: TimeInterval = 0

    override init() {
        Preferences.register()
        // Without a saved position a new item lands at the far left, which on a crowded
        // notched display is behind the notch. Start both beside the system items.
        Self.seedPosition(0, for: "toggle")
        Self.seedPosition(1, for: "divider")
        isCollapsed = UserDefaults.standard.bool(forKey: Self.onboardedKey)

        toggle = NSStatusBar.system.statusItem(withLength: Metric.toggleLength)
        divider = NSStatusBar.system.statusItem(withLength: 0)
        super.init()

        toggle.autosaveName = "toggle"
        divider.autosaveName = "divider"

        if let button = toggle.button {
            button.target = self
            button.action = #selector(toggleClicked)
            // Menu bar extras respond on press, not release.
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
            // An image view rather than the button's own image, so the chevron can use
            // the system symbol transitions.
            chevron.frame = button.bounds
            chevron.autoresizingMask = [.width, .height]
            chevron.symbolConfiguration = .init(pointSize: 13, weight: .semibold)
            button.addSubview(chevron)
        }
        divider.button?.image = Self.dividerImage
        divider.button?.appearsDisabled = true
        divider.button?.setAccessibilityLabel("Hidden items divider")

        // Mouse and scroll events need no permission. Modifiers and hover are polled,
        // only while the pointer is in the menu bar.
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown, .scrollWheel]
        ) { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
        }

        apply(animated: false)

        if !isCollapsed {
            // Give the status bar a moment to lay the items out before anchoring to one.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                MainActor.assumeIsolated { self?.showTips() }
            }
        }
    }

    private static func positionKey(_ name: String) -> String {
        "NSStatusItem Preferred Position \(name)"
    }

    private static func seedPosition(_ position: Double, for name: String) {
        if UserDefaults.standard.object(forKey: positionKey(name)) == nil {
            UserDefaults.standard.set(position, forKey: positionKey(name))
        }
    }

    // MARK: State

    private func setCollapsed(_ collapsed: Bool) {
        guard collapsed != isCollapsed else { return }
        isCollapsed = collapsed
        revealedByHover = false
        // A deliberate toggle shouldn't be undone by hover until the pointer leaves the bar.
        hoverArmed = false
        collapseTimer?.invalidate()
        if !collapsed { scheduleAutoCollapse() }
        apply()
    }

    private func apply(animated: Bool = true) {
        let revealed = isPeeking || !isCollapsed
        let motion = animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        if revealed {
            divider.length = Metric.dividerLength
        } else {
            divider.length = dividerIsLeftOfToggle ? Metric.hiddenLength : 0
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = motion ? Metric.fadeDuration : 0
            divider.button?.animator().alphaValue = revealed ? 1 : 0
        }

        let symbol = isCollapsed ? "chevron.compact.left" : "chevron.compact.right"
        guard symbol != chevronSymbol,
              let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) else { return }
        if motion && chevronSymbol != nil {
            chevron.setSymbolImage(image, contentTransition: .replace.downUp)
        } else {
            chevron.image = image
        }
        chevronSymbol = symbol
        toggle.button?.setAccessibilityLabel(isCollapsed ? "Show hidden menu bar items" : "Hide menu bar items")
    }

    /// If the divider was dragged to the right of the toggle, collapsing would push
    /// the toggle off-screen with everything else. macOS records each item's distance
    /// from the right edge as it moves, which is known before the items are laid out.
    private var dividerIsLeftOfToggle: Bool {
        let defaults = UserDefaults.standard
        return defaults.double(forKey: Self.positionKey("divider")) > defaults.double(forKey: Self.positionKey("toggle"))
    }

    // MARK: Events

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            if Preferences.isOn(Preferences.showOnClick),
               MenuBar.isEmptySpace(NSEvent.mouseLocation, ignoring: Self.itemNames) {
                setCollapsed(!isCollapsed)
            }
        case .scrollWheel:
            scrolled(event)
        default:
            startPolling()
        }
    }

    /// Pulling down on the menu bar reveals; pushing up hides.
    private func scrolled(_ event: NSEvent) {
        guard Preferences.isOn(Preferences.showOnScroll), MenuBar.contains(NSEvent.mouseLocation) else { return }
        if event.phase == .began || event.timestamp - lastScroll > Metric.scrollGestureGap {
            scrollTotal = 0
            scrollHandled = false
        }
        lastScroll = event.timestamp
        guard !scrollHandled else { return }

        // In finger terms, so natural and classic scrolling feel the same; a wheel
        // reports lines rather than points.
        let delta = event.isDirectionInvertedFromDevice ? event.scrollingDeltaY : -event.scrollingDeltaY
        scrollTotal += event.hasPreciseScrollingDeltas ? delta : delta * 10
        guard abs(scrollTotal) >= Metric.scrollThreshold else { return }
        scrollHandled = true
        setCollapsed(scrollTotal < 0)
    }

    private func startPolling() {
        guard poll == nil, isPeeking || revealedByHover || MenuBar.contains(NSEvent.mouseLocation) else { return }
        let timer = Timer(timeInterval: Metric.pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        poll = timer
    }

    private func tick() {
        let pointer = NSEvent.mouseLocation
        let modifiers = NSEvent.modifierFlags.intersection([.command, .option, .control, .shift])
        let commandOnly = modifiers == .command
        let mouseDown = NSEvent.pressedMouseButtons != 0
        let inMenuBar = MenuBar.contains(pointer)

        updatePeek(commandOnly: commandOnly, inMenuBar: inMenuBar, mouseDown: mouseDown)
        if !isPeeking {
            updateHover(pointer: pointer, inMenuBar: inMenuBar, idle: modifiers.isEmpty && !mouseDown)
        }

        if !isPeeking && !revealedByHover && !inMenuBar {
            poll?.invalidate()
            poll = nil
            hoverArmed = true
        }
    }

    private func updatePeek(commandOnly: Bool, inMenuBar: Bool, mouseDown: Bool) {
        if isPeeking {
            // Changing the divider mid-drag would yank the item out from under the cursor.
            if !commandOnly && !mouseDown {
                isPeeking = false
                apply()
            }
        } else if commandOnly && inMenuBar && !mouseDown {
            // The delay keeps ⌘-Tab and shortcuts from flashing the bar.
            let since = commandHeldSince ?? Date()
            commandHeldSince = since
            if Date().timeIntervalSince(since) >= Metric.peekDelay {
                isPeeking = true
                commandHeldSince = nil
                apply()
            }
        } else {
            commandHeldSince = nil
        }
    }

    private func updateHover(pointer: NSPoint, inMenuBar: Bool, idle: Bool) {
        let overEmptySpace = inMenuBar && MenuBar.isEmptySpace(pointer, ignoring: Self.itemNames)
        if !overEmptySpace { hoverSince = nil }

        if isCollapsed && overEmptySpace && hoverArmed && idle && Preferences.isOn(Preferences.showOnHover) {
            let since = hoverSince ?? Date()
            hoverSince = since
            if Date().timeIntervalSince(since) >= Metric.hoverDelay {
                isCollapsed = false
                revealedByHover = true
                hoverSince = nil
                apply()
            }
        }

        guard revealedByHover else { return }
        // Stay open while the pointer is in the bar or in a menu opened from it.
        if inMenuBar || !idle || MenuBar.isMenuOpen {
            hoverExitSince = nil
            return
        }
        let since = hoverExitSince ?? Date()
        hoverExitSince = since
        if Date().timeIntervalSince(since) >= Metric.hoverExitDelay {
            hoverExitSince = nil
            setCollapsed(true)
        }
    }

    private static let dividerImage: NSImage = {
        let image = NSImage(size: NSSize(width: 1.5, height: 14), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 0.75, yRadius: 0.75).fill()
            return true
        }
        image.isTemplate = true
        return image
    }()

    // MARK: Toggle

    @objc private func toggleClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseDown || event?.modifierFlags.contains(.control) == true {
            showMenu()
            return
        }
        setCollapsed(!isCollapsed)
    }

    private func scheduleAutoCollapse() {
        collapseTimer = Timer.scheduledTimer(withTimeInterval: Metric.autoCollapse, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, !self.isCollapsed else { return }
                // Wait while the user is still working in the menu bar or one of its menus.
                if self.isPeeking || MenuBar.contains(NSEvent.mouseLocation) || MenuBar.isMenuOpen
                    || NSEvent.pressedMouseButtons != 0 {
                    self.scheduleAutoCollapse()
                    return
                }
                self.setCollapsed(true)
            }
        }
    }

    // MARK: Menu

    private func showMenu() {
        let menu = NSMenu()

        let tips = NSMenuItem(title: "How to Arrange…", action: #selector(showTips), keyEquivalent: "")
        tips.target = self
        menu.addItem(tips)
        menu.addItem(.separator())

        let login = NSMenuItem(title: "Open at Login", action: #selector(toggleOpenAtLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Quit Reasonal", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        toggle.menu = menu
        toggle.button?.performClick(nil)
        toggle.menu = nil
    }

    // MARK: Tips

    /// Shown with the hidden items revealed, so the divider the text describes is on screen.
    @objc private func showTips() {
        guard let button = toggle.button, tipsPopover == nil else { return }
        collapseTimer?.invalidate()
        isCollapsed = false
        apply()

        let popover = NSPopover()
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: TipsView { [weak popover] in
            popover?.performClose(nil)
        })
        tipsPopover = popover
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func toggleOpenAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSApp.activate()
            NSAlert(error: error).runModal()
        }
    }
}

extension MenuBarController: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        tipsPopover = nil
        UserDefaults.standard.set(true, forKey: Self.onboardedKey)
        scheduleAutoCollapse()
    }
}

/// Lets clicks fall through to the status bar button underneath.
private final class PassthroughImageView: NSImageView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
