import AppKit
import BarKit

/// Three status items, right to left: a chevron that toggles, an invisible divider
/// kept directly left of it, and a dotted always-hidden divider. Collapsing stretches a
/// divider so everything left of it is pushed off-screen, so whatever is dragged past
/// the chevron hides. A normal reveal shrinks only the first divider; ⌥-click or holding
/// ⌘ shrinks both, and ⌘ also lets the system's own ⌘-drag rearrange them.
@MainActor
final class MenuBarController: NSObject {
    private enum Metric {
        /// Just wide enough for the chevron; macOS adds its own padding either side.
        static let toggleLength: CGFloat = 10
        /// Wider than macOS's bare padding, so `ChevronLocator` never takes a spacer for the divider.
        static let spacerLength: CGFloat = 8
        static let pollInterval: TimeInterval = 1.0 / 30
        static let fadeDuration: TimeInterval = 0.12
        /// How long Control Center takes to add a new status item before its length can be set.
        static let settle: TimeInterval = 0.25
    }

    private static let onboardedKey = "onboarded"
    /// Where the always-hidden divider was before it was parked, to put it back there.
    private static let alwaysDividerHomeKey = "alwaysDividerHome"

    private let toggle: NSStatusItem
    private var divider: NSStatusItem
    private var alwaysDivider: NSStatusItem
    private var chevronPointsLeft: Bool?
    private var spacers: [NSStatusItem] = []
    private var dividerParked = false
    /// Whether saved positions should be checked for icons dropped beside the chevron.
    /// Only a ⌘-drag can put one there, so this is set at launch and when a peek ends.
    private var checkPin = true
    /// Items recreated during the current layout pass, by name.
    private var recreatedThisPass: Set<String> = []
    private var alwaysDividerParked = UserDefaults.standard.object(forKey: alwaysDividerHomeKey) != nil
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

        toggle = NSStatusBar.system.statusItem(withLength: Metric.toggleLength)
        divider = Self.makeDivider()
        alwaysDivider = Self.makeAlwaysDivider()
        super.init()

        toggle.autosaveName = ItemName.toggle

        if let button = toggle.button {
            button.target = self
            button.action = #selector(toggleClicked)
            // Menu bar extras respond on press, not release.
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
            button.imagePosition = .imageOnly
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

        // Give the status bar a moment to lay the items out: the how-to plays beside the
        // chevron, and pinning the divider needs the chevron's width.
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
        if reveal.isCollapsed && !peek.isPeeking { pinDivider() }
        let alwaysHidden = Preferences.isOn(Preferences.alwaysHiddenSection)
        var layout = DividerLayout(
            reveal: reveal, isPeeking: peek.isPeeking, positions: Self.positions, alwaysHidden: alwaysHidden)
        if layout.parksDivider { parkDivider() }
        if layout.parksAlwaysDivider != alwaysDividerParked {
            layout.parksAlwaysDivider ? parkAlwaysDivider() : unparkAlwaysDivider()
            // Unparking moves it, which changes whether it is in order.
            layout = DividerLayout(
                reveal: reveal, isPeeking: peek.isPeeking, positions: Self.positions, alwaysHidden: alwaysHidden)
        }
        // A length set in the pass that creates an item is dropped as Control Center adds it
        // to the bar, and setting the same length again later is a no-op, so a recreated
        // item keeps its creation length now and gets its real one once it has settled.
        if !recreatedThisPass.contains(ItemName.divider) { divider.length = layout.dividerLength }
        if !recreatedThisPass.contains(ItemName.alwaysDivider) { alwaysDivider.length = layout.alwaysDividerLength }
        if !recreatedThisPass.isEmpty {
            recreatedThisPass = []
            DispatchQueue.main.asyncAfter(deadline: .now() + Metric.settle) { [weak self] in
                MainActor.assumeIsolated { self?.apply(animated: false) }
            }
        }
        alwaysDivider.button?.setAccessibilityElement(alwaysHidden)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = motion ? Metric.fadeDuration : 0
            alwaysDivider.button?.animator().alphaValue = layout.showsAlwaysDivider ? 1 : 0
            // Spacers are blank except while arranging, so they can be found and dragged.
            for spacer in spacers {
                spacer.button?.animator().alphaValue = peek.isPeeking ? 1 : 0
            }
        }

        // Swapped outright, as other menu bar icons do; the divider fade carries the motion.
        guard reveal.isCollapsed != chevronPointsLeft else { return }
        chevronPointsLeft = reveal.isCollapsed
        toggle.button?.image = reveal.isCollapsed ? Glyphs.chevronLeft : Glyphs.chevronRight
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

    private static func makeAlwaysDivider() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: 0)
        item.autosaveName = ItemName.alwaysDivider
        item.button?.image = Glyphs.dottedLine
        item.button?.appearsDisabled = true
        item.button?.setAccessibilityLabel("Always-hidden items divider")
        return item
    }

    /// Moves a status item by recreating it: an item takes its saved position only when created.
    private func recreate(
        _ item: NSStatusItem, named name: String, at position: Double, using make: () -> NSStatusItem
    ) -> NSStatusItem {
        recreatedThisPass.insert(name)
        NSStatusBar.system.removeStatusItem(item)
        UserDefaults.standard.set(position, forKey: Self.positionKey(name))
        return make()
    }

    private func parkDivider() {
        guard !dividerParked else { return }
        divider = recreate(divider, named: ItemName.divider, at: ItemPositions.parked) { Self.makeDivider() }
        dividerParked = true
    }

    private func parkAlwaysDivider() {
        guard !alwaysDividerParked else { return }
        UserDefaults.standard.set(Self.position(of: ItemName.alwaysDivider), forKey: Self.alwaysDividerHomeKey)
        alwaysDivider = recreate(
            alwaysDivider, named: ItemName.alwaysDivider, at: ItemPositions.parked, using: Self.makeAlwaysDivider)
        alwaysDividerParked = true
    }

    /// Back where it was before it was parked, or just left of the divider the first time.
    private func unparkAlwaysDivider() {
        guard alwaysDividerParked else { return }
        let defaults = UserDefaults.standard
        let home =
            defaults.object(forKey: Self.alwaysDividerHomeKey) as? Double ?? Self.position(of: ItemName.divider) + 1
        defaults.removeObject(forKey: Self.alwaysDividerHomeKey)
        alwaysDivider = recreate(
            alwaysDivider, named: ItemName.alwaysDivider, at: home, using: Self.makeAlwaysDivider)
        alwaysDividerParked = false
    }

    /// Moves the divider back directly left of the chevron when icons were dropped
    /// between them, so dragging an icon past the chevron is what hides it. A status
    /// item takes its saved position only when created, so the divider is recreated.
    private func pinDivider() {
        guard let width = toggle.button?.window?.frame.width else { return }
        // Saved positions are only read when an icon may have moved: just after the divider
        // is recreated, removing the old item can still write its last position back.
        let target: Double?
        if dividerParked {
            target = Self.position(of: ItemName.toggle) + 1
        } else if checkPin {
            target = Self.positions.dividerRepin(toggleWidth: Double(width))
        } else {
            target = nil
        }
        checkPin = false
        guard let target else { return }
        divider = recreate(divider, named: ItemName.divider, at: target) { Self.makeDivider() }
        dividerParked = false
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
            if peek.isPeeking { demo.close() } else { checkPin = true }
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
        guard let chevron = MenuBar.chevronFrame(on: screen, chevronLength: Metric.toggleLength) else {
            // The chevron is recognised by the divider flush against it, which is parked
            // while revealed; bring it back at zero length while looking.
            if dividerParked {
                divider = recreate(divider, named: ItemName.divider, at: Self.position(of: ItemName.toggle) + 1) {
                    Self.makeDivider()
                }
                dividerParked = false
            }
            guard attemptsLeft > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                MainActor.assumeIsolated { self?.playDemo(attemptsLeft: attemptsLeft - 1) }
            }
            return
        }
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
