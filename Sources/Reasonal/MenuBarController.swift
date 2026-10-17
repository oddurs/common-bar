import AppKit
import BarKit

/// Three status items, right to left: a chevron that toggles, a divider left of it, and
/// an always-hidden divider further left. Collapsing stretches a divider so everything
/// left of it is pushed off-screen. A normal reveal takes the first divider down to nothing;
/// ⌥-click shows the always-hidden section too, and holding ⌘ shows both dividers as
/// marks so icons can be ⌘-dragged across them.
@MainActor
final class MenuBarController: NSObject {
    private enum Metric {
        /// Just wide enough for the chevron; macOS adds its own padding either side.
        static let toggleLength: CGFloat = 10
        /// About the width of a small icon.
        static let spacerLength: CGFloat = 8
        static let pollInterval: TimeInterval = 1.0 / 30
        static let fadeDuration: TimeInterval = 0.12
    }

    private static let onboardedKey = "onboarded"
    /// Written by an earlier version that moved the always-hidden divider aside; cleared on launch.
    private static let retiredAlwaysDividerHomeKey = "alwaysDividerHome"

    private let toggle: NSStatusItem
    private let divider: DividerItem
    private let alwaysDivider: DividerItem
    private let chevron = ChevronView()
    private var chevronPointsLeft: Bool?
    private var spacers: [NSStatusItem] = []
    private var syncingSpacers = false
    private var reveal: Reveal
    private var peek = Peek()
    private var hover = Hover()
    private var scroll = ScrollGesture()
    private var poll: Timer?
    private var collapseTimer: Timer?
    private var eventMonitor: Any?
    private var preferencesObserver: Any?
    private var alwaysHidden = Preferences.isOn(Preferences.alwaysHiddenSection)
    private let demo = DragDemoOverlay()
    private let settings = SettingsWindow()

    override init() {
        Preferences.register()
        Self.seedPositions()
        reveal = Reveal(isCollapsed: UserDefaults.standard.bool(forKey: Self.onboardedKey))

        UserDefaults.standard.removeObject(forKey: Self.retiredAlwaysDividerHomeKey)
        DividerItem.markVisible(ItemName.toggle)
        toggle = NSStatusBar.system.statusItem(withLength: Metric.toggleLength)
        divider = DividerItem(named: ItemName.divider, marker: Glyphs.line)
        alwaysDivider = DividerItem(named: ItemName.alwaysDivider, marker: Glyphs.dottedLine)
        super.init()

        toggle.autosaveName = ItemName.toggle

        if let button = toggle.button {
            button.target = self
            button.action = #selector(toggleClicked)
            // Menu bar extras respond on press, not release.
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
            // A view of its own, so the glyph can turn without the button's highlight turning too.
            chevron.image = Glyphs.chevron
            chevron.imageScaling = .scaleNone
            chevron.frame = button.bounds
            chevron.wantsLayer = true
            button.addSubview(chevron)
        }

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

        syncSpacers()
        apply(animated: false)

        // Give the status bar a moment to lay the items out: the how-to plays beside the chevron.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.reveal.isCollapsed { self.apply(animated: false) } else { self.showDemo() }
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
        let alwaysHidden = Preferences.isOn(Preferences.alwaysHiddenSection)
        let layout = DividerLayout(
            reveal: reveal, isPeeking: peek.isPeeking, positions: Self.positions, alwaysHidden: alwaysHidden)
        divider.set(layout.divider, animated: motion)
        alwaysDivider.set(layout.alwaysDivider, animated: motion)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = motion ? Metric.fadeDuration : 0
            // Spacers are blank except while arranging, so they can be found and dragged.
            for spacer in spacers {
                spacer.button?.animator().alphaValue = peek.isPeeking ? 1 : 0
            }
        }

        // The chevron turns as the icons glide, pointing the way they are going: left, where
        // the hidden icons wait, while closed; back towards them to close while open. The
        // curve overshoots a touch and settles, over about as long as the glide.
        guard reveal.isCollapsed != chevronPointsLeft else { return }
        let firstLayout = chevronPointsLeft == nil
        chevronPointsLeft = reveal.isCollapsed
        chevron.turn(to: reveal.isCollapsed ? 0 : .pi, animated: motion && !firstLayout)
        toggle.button?.setAccessibilityLabel(reveal.isCollapsed ? "Show hidden menu bar items" : "Hide menu bar items")
    }

    private static var positions: ItemPositions {
        ItemPositions(
            toggle: position(of: ItemName.toggle),
            divider: position(of: ItemName.divider),
            alwaysDivider: position(of: ItemName.alwaysDivider))
    }

    private func preferencesChanged() {
        syncSpacers()
        let enabled = Preferences.isOn(Preferences.alwaysHiddenSection)
        // Item positions are saved to the same defaults on every move; only this setting matters here.
        guard enabled != alwaysHidden else { return }
        alwaysHidden = enabled
        if !enabled && reveal.showsAlwaysHidden {
            _ = reveal.set(collapsed: reveal.isCollapsed, showingAlwaysHidden: false)
        }
        apply()
    }

    /// Adds or removes spacers to match Settings. A removed spacer keeps its saved
    /// position, so adding it back puts it where it was.
    private func syncSpacers() {
        // Seeding a position below writes to the defaults, which calls back here.
        guard !syncingSpacers else { return }
        syncingSpacers = true
        defer { syncingSpacers = false }
        let count = Preferences.spacerCount
        while spacers.count > count {
            NSStatusBar.system.removeStatusItem(spacers.removeLast())
        }
        while spacers.count < count {
            let name = ItemName.spacer(spacers.count)
            if Self.savedPosition(of: name) == nil {
                UserDefaults.standard.set(
                    Spacers.seedPosition(toggle: Self.position(of: ItemName.toggle)), forKey: Self.positionKey(name))
            }
            DividerItem.markVisible(name)
            let item = NSStatusBar.system.statusItem(withLength: Metric.spacerLength)
            item.autosaveName = name
            item.button?.image = Glyphs.spacer
            item.button?.appearsDisabled = true
            item.button?.alphaValue = peek.isPeeking ? 1 : 0
            item.button?.setAccessibilityElement(false)
            spacers.append(item)
        }
    }

    // MARK: Events

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            demo.close()
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
            // Holding ⌘ is the how-to's first step; the user has it from here.
            if peek.isPeeking { demo.close() }
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

    // MARK: Toggle

    @objc private func toggleClicked() {
        demo.close()
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

        let tips = NSMenuItem(title: "How to Arrange…", action: #selector(showDemo), keyEquivalent: "")
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

    // MARK: How-to

    /// Played with the hidden items revealed, beside the chevron the user will drag past.
    @objc private func showDemo() {
        playDemo(attemptsLeft: 8)
    }

    /// Just after launch the window server may not have laid the items out yet, so the
    /// chevron is looked for again for a moment before giving up.
    private func playDemo(attemptsLeft: Int) {
        guard !demo.isShowing, let button = toggle.button, let screen = NSScreen.main ?? NSScreen.screens.first
        else { return }
        // AppKit's frame for a status item can lag where Control Center has put it, so it is
        // trusted only once the window server shows an item at the same place.
        guard let window = button.window, MenuBar.hasStatusItem(at: window.frame, on: screen) else {
            guard attemptsLeft > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                MainActor.assumeIsolated { self?.playDemo(attemptsLeft: attemptsLeft - 1) }
            }
            return
        }
        let chevron = window.frame
        collapseTimer?.invalidate()
        reveal.expand()
        apply()
        demo.show(beside: chevron, appearance: button.effectiveAppearance) { [weak self] in
            UserDefaults.standard.set(true, forKey: Self.onboardedKey)
            self?.scheduleAutoCollapse()
        }
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
