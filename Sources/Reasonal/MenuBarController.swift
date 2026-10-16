import AppKit
import BarKit
import SwiftUI
import Symbols

/// Three status items, right to left: a chevron that toggles, an invisible divider
/// kept directly left of it, and a dotted always-hidden divider. Collapsing stretches a
/// divider so everything left of it is pushed off-screen, so whatever is dragged past
/// the chevron hides. A normal reveal shrinks only the first divider; ⌥-click or holding
/// ⌘ shrinks both, and ⌘ also lets the system's own ⌘-drag rearrange them.
@MainActor
final class MenuBarController: NSObject {
    private enum Metric {
        static let toggleLength: CGFloat = 24
        static let pollInterval: TimeInterval = 1.0 / 30
        static let fadeDuration: TimeInterval = 0.12
    }

    private static let onboardedKey = "onboarded"

    private let toggle: NSStatusItem
    private var divider: NSStatusItem
    private let alwaysDivider: NSStatusItem
    private let chevron = PassthroughImageView()
    private var chevronSymbol: String?
    private var reveal: Reveal
    private var peek = Peek()
    private var hover = Hover()
    private var scroll = ScrollGesture()
    private var poll: Timer?
    private var collapseTimer: Timer?
    private var eventMonitor: Any?
    private var preferencesObserver: Any?
    private var alwaysHidden = Preferences.isOn(Preferences.alwaysHiddenSection)
    private var tipsPopover: NSPopover?
    private let settings = SettingsWindow()

    override init() {
        Preferences.register()
        Self.seedPositions()
        reveal = Reveal(isCollapsed: UserDefaults.standard.bool(forKey: Self.onboardedKey))

        toggle = NSStatusBar.system.statusItem(withLength: Metric.toggleLength)
        divider = Self.makeDivider()
        alwaysDivider = NSStatusBar.system.statusItem(withLength: 0)
        super.init()

        toggle.autosaveName = ItemName.toggle
        alwaysDivider.autosaveName = ItemName.alwaysDivider

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
        alwaysDivider.button?.image = Self.alwaysDividerImage
        alwaysDivider.button?.appearsDisabled = true
        alwaysDivider.button?.setAccessibilityLabel("Always-hidden items divider")

        // Mouse and scroll events need no permission. Modifiers and hover are polled,
        // only while the pointer is in the menu bar.
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown, .scrollWheel]
        ) { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
        }

        // Settings apply at once; turning the always-hidden section off releases its icons.
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.preferencesChanged() }
        }

        apply(animated: false)

        // Give the status bar a moment to lay the items out: the tips anchor to the
        // chevron, and pinning the divider needs the chevron's width.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.reveal.isCollapsed { self.apply(animated: false) } else { self.showTips() }
            }
        }
    }

    private static func positionKey(_ name: String) -> String {
        "NSStatusItem Preferred Position \(name)"
    }

    /// Distance from the right edge of the screen; larger is further left.
    private static func position(of name: String) -> Double {
        UserDefaults.standard.double(forKey: positionKey(name))
    }

    private static func savedPosition(of name: String) -> Double? {
        UserDefaults.standard.object(forKey: positionKey(name)) == nil ? nil : position(of: name)
    }

    /// Writes a starting position for each item macOS hasn't saved one for yet.
    private static func seedPositions() {
        let seeded = ItemPositions.seeded(
            toggle: savedPosition(of: ItemName.toggle),
            divider: savedPosition(of: ItemName.divider),
            alwaysDivider: savedPosition(of: ItemName.alwaysDivider))
        let positions = [
            (ItemName.toggle, seeded.toggle),
            (ItemName.divider, seeded.divider),
            (ItemName.alwaysDivider, seeded.alwaysDivider),
        ]
        for (name, position) in positions where savedPosition(of: name) == nil {
            UserDefaults.standard.set(position, forKey: positionKey(name))
        }
    }

    // MARK: State

    private func setCollapsed(_ collapsed: Bool, showingAlwaysHidden: Bool = false) {
        guard reveal.set(collapsed: collapsed, showingAlwaysHidden: showingAlwaysHidden) else { return }
        // A deliberate toggle shouldn't be undone by hover until the pointer leaves the bar.
        hover.toggled()
        collapseTimer?.invalidate()
        if !collapsed { scheduleAutoCollapse() }
        apply()
    }

    private func apply(animated: Bool = true) {
        let motion = animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if reveal.isCollapsed && !peek.isPeeking { pinDivider() }
        let alwaysHidden = Preferences.isOn(Preferences.alwaysHiddenSection)
        let layout = DividerLayout(
            reveal: reveal, isPeeking: peek.isPeeking, positions: Self.positions, alwaysHidden: alwaysHidden)
        divider.length = layout.dividerLength
        alwaysDivider.length = layout.alwaysDividerLength
        alwaysDivider.button?.setAccessibilityElement(alwaysHidden)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = motion ? Metric.fadeDuration : 0
            alwaysDivider.button?.animator().alphaValue = layout.showsAlwaysDivider ? 1 : 0
        }

        let symbol = reveal.isCollapsed ? "chevron.compact.left" : "chevron.compact.right"
        guard symbol != chevronSymbol,
            let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        else { return }
        if motion && chevronSymbol != nil {
            chevron.setSymbolImage(image, contentTransition: .replace.downUp)
        } else {
            chevron.image = image
        }
        chevronSymbol = symbol
        toggle.button?.setAccessibilityLabel(reveal.isCollapsed ? "Show hidden menu bar items" : "Hide menu bar items")
    }

    private static var positions: ItemPositions {
        ItemPositions(
            toggle: position(of: ItemName.toggle),
            divider: position(of: ItemName.divider),
            alwaysDivider: position(of: ItemName.alwaysDivider))
    }

    private static func makeDivider() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: 0)
        item.autosaveName = ItemName.divider
        item.button?.setAccessibilityElement(false)
        return item
    }

    /// Moves the divider back directly left of the chevron when icons were dropped
    /// between them, so dragging an icon past the chevron is what hides it. A status
    /// item takes its saved position only when created, so the divider is recreated.
    private func pinDivider() {
        guard let width = toggle.button?.window?.frame.width,
            let target = Self.positions.dividerRepin(toggleWidth: Double(width))
        else { return }
        NSStatusBar.system.removeStatusItem(divider)
        UserDefaults.standard.set(target, forKey: Self.positionKey(ItemName.divider))
        divider = Self.makeDivider()
    }

    private func preferencesChanged() {
        let enabled = Preferences.isOn(Preferences.alwaysHiddenSection)
        // Item positions are saved to the same defaults on every move; only this setting matters here.
        guard enabled != alwaysHidden else { return }
        alwaysHidden = enabled
        if !enabled && reveal.showsAlwaysHidden {
            _ = reveal.set(collapsed: reveal.isCollapsed, showingAlwaysHidden: false)
        }
        apply()
    }

    // MARK: Events

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            if Preferences.isOn(Preferences.showOnClick),
                MenuBar.isEmptySpace(NSEvent.mouseLocation, ignoring: ItemName.all)
            {
                setCollapsed(!reveal.isCollapsed)
            }
        case .scrollWheel:
            scrolled(event)
        default:
            startPolling()
        }
    }

    private func scrolled(_ event: NSEvent) {
        guard Preferences.isOn(Preferences.showOnScroll), MenuBar.contains(NSEvent.mouseLocation) else { return }
        let intent = scroll.add(
            deltaY: Double(event.scrollingDeltaY), began: event.phase == .began, timestamp: event.timestamp,
            precise: event.hasPreciseScrollingDeltas, inverted: event.isDirectionInvertedFromDevice)
        if let intent { setCollapsed(intent == .hide) }
    }

    private func startPolling() {
        guard poll == nil, peek.isPeeking || hover.revealed || MenuBar.contains(NSEvent.mouseLocation) else { return }
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
        let now = Date()

        if peek.update(commandOnly: commandOnly, inMenuBar: inMenuBar, mouseDown: mouseDown, now: now) {
            apply()
        }
        if !peek.isPeeking {
            let action = hover.update(
                isCollapsed: reveal.isCollapsed,
                overEmptySpace: inMenuBar && MenuBar.isEmptySpace(pointer, ignoring: ItemName.all),
                inMenuBar: inMenuBar, idle: modifiers.isEmpty && !mouseDown,
                enabled: Preferences.isOn(Preferences.showOnHover), menuOpen: MenuBar.isMenuOpen, now: now)
            switch action {
            case .none:
                break
            case .reveal:
                reveal.expand()
                apply()
            case .collapse:
                setCollapsed(true)
            }
        }

        // The pointer has left the bar, so hover may reveal again.
        if !peek.isPeeking && !hover.revealed && !inMenuBar {
            poll?.invalidate()
            poll = nil
            hover.rearm()
        }
    }

    /// Dotted, so it reads as a boundary rather than an icon while arranging.
    private static let alwaysDividerImage: NSImage = {
        let image = NSImage(size: NSSize(width: 2, height: 14), flipped: false) { rect in
            NSColor.black.setFill()
            for y in stride(from: rect.minY, to: rect.maxY, by: 4) {
                NSBezierPath(ovalIn: NSRect(x: rect.minX, y: y, width: 2, height: 2)).fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }()

    // MARK: Toggle

    @objc private func toggleClicked() {
        let event = NSApp.currentEvent
        let modifiers = event?.modifierFlags ?? []
        if event?.type == .rightMouseDown || modifiers.contains(.control) {
            showMenu()
            return
        }
        let next = reveal.afterClick(
            option: modifiers.contains(.option), alwaysHidden: Preferences.isOn(Preferences.alwaysHiddenSection))
        setCollapsed(next.collapsed, showingAlwaysHidden: next.showingAlwaysHidden)
    }

    private func scheduleAutoCollapse() {
        guard let delay = Preferences.autoHideDelay.interval else { return }
        collapseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, !self.reveal.isCollapsed else { return }
                // Wait while the user is still working in the menu bar or one of its menus.
                if self.peek.isPeeking || MenuBar.contains(NSEvent.mouseLocation) || MenuBar.isMenuOpen
                    || NSEvent.pressedMouseButtons != 0
                {
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

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        menu.addItem(
            NSMenuItem(title: "Quit Common Bar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        toggle.menu = menu
        toggle.button?.performClick(nil)
        toggle.menu = nil
    }

    // MARK: Tips

    /// Shown with the hidden items revealed, so the divider the text describes is on screen.
    @objc private func showTips() {
        guard let button = toggle.button, tipsPopover == nil else { return }
        collapseTimer?.invalidate()
        reveal.expand()
        apply()

        let popover = NSPopover()
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: TipsView { [weak popover] in
                popover?.performClose(nil)
            })
        tipsPopover = popover
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc func showSettings() {
        settings.show()
    }
}

extension MenuBarController: NSApplicationDelegate {
    /// Opening the app again while it runs is how people look for its settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
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
