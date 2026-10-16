import BarKit
import Foundation
import Testing

@Suite struct HoverTests {
    let start = Date(timeIntervalSinceReferenceDate: 0)

    func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    /// One poll with the pointer resting on empty menu bar space.
    func overEmpty(
        _ hover: inout Hover, collapsed: Bool = true, idle: Bool = true, enabled: Bool = true, _ t: TimeInterval
    ) -> Hover.Action {
        hover.update(
            isCollapsed: collapsed, overEmptySpace: true, inMenuBar: true, idle: idle, enabled: enabled,
            menuOpen: false, now: at(t))
    }

    /// One poll with the pointer outside the menu bar.
    func outside(_ hover: inout Hover, menuOpen: Bool = false, idle: Bool = true, _ t: TimeInterval) -> Hover.Action {
        hover.update(
            isCollapsed: false, overEmptySpace: false, inMenuBar: false, idle: idle, enabled: true,
            menuOpen: menuOpen, now: at(t))
    }

    func revealed() -> Hover {
        var hover = Hover()
        _ = overEmpty(&hover, 0)
        _ = overEmpty(&hover, 1)
        return hover
    }

    @Test func restingOnEmptySpaceReveals() {
        var hover = Hover()
        var action = overEmpty(&hover, 0)
        #expect(action == .none)
        action = overEmpty(&hover, 0.1)
        #expect(action == .none)
        action = overEmpty(&hover, Hover.delay)
        #expect(action == .reveal)
        #expect(hover.revealed)
    }

    @Test func passingOverAnItemRestartsTheWait() {
        var hover = Hover()
        _ = overEmpty(&hover, 0)
        _ = hover.update(
            isCollapsed: true, overEmptySpace: false, inMenuBar: true, idle: true, enabled: true, menuOpen: false,
            now: at(0.2))
        var action = overEmpty(&hover, 0.3)
        #expect(action == .none)
        action = overEmpty(&hover, 0.55)
        #expect(action == .reveal)
    }

    @Test func nothingHappensWhenAlreadyShownDisabledOrBusy() {
        var shown = Hover()
        _ = overEmpty(&shown, collapsed: false, 0)
        var action = overEmpty(&shown, collapsed: false, 1)
        #expect(action == .none)

        var disabled = Hover()
        _ = overEmpty(&disabled, enabled: false, 0)
        action = overEmpty(&disabled, enabled: false, 1)
        #expect(action == .none)

        var busy = Hover()
        _ = overEmpty(&busy, idle: false, 0)
        action = overEmpty(&busy, idle: false, 1)
        #expect(action == .none)
    }

    @Test func leavingTheBarCollapsesAfterTheExitDelay() {
        var hover = revealed()
        var action = outside(&hover, 2)
        #expect(action == .none)
        action = outside(&hover, 2.3)
        #expect(action == .none)
        action = outside(&hover, 2 + Hover.exitDelay)
        #expect(action == .collapse)
    }

    @Test func returningToTheBarCancelsTheExit() {
        var hover = revealed()
        _ = outside(&hover, 2)
        _ = overEmpty(&hover, collapsed: false, 2.3)
        var action = outside(&hover, 2.6)
        #expect(action == .none)
        action = outside(&hover, 3.1)
        #expect(action == .collapse)
    }

    @Test func anOpenMenuOrHeldButtonKeepsItOpen() {
        var hover = revealed()
        var action = outside(&hover, menuOpen: true, 2)
        #expect(action == .none)
        action = outside(&hover, menuOpen: true, 5)
        #expect(action == .none)
        action = outside(&hover, idle: false, 6)
        #expect(action == .none)
        action = outside(&hover, 6.2)
        #expect(action == .none)
        action = outside(&hover, 6.7)
        #expect(action == .collapse)
    }

    @Test func menuOpenIsOnlyAskedWhileWaitingToClose() {
        var hover = Hover()
        var asked = 0
        func menuOpen() -> Bool {
            asked += 1
            return false
        }
        _ = hover.update(
            isCollapsed: true, overEmptySpace: false, inMenuBar: false, idle: true, enabled: true,
            menuOpen: menuOpen(), now: at(0))
        #expect(asked == 0)

        hover = revealed()
        _ = hover.update(
            isCollapsed: false, overEmptySpace: false, inMenuBar: false, idle: true, enabled: true,
            menuOpen: menuOpen(), now: at(2))
        #expect(asked == 1)
    }

    @Test func aDeliberateToggleDisarmsHoverUntilRearmed() {
        var hover = revealed()
        hover.toggled()
        #expect(!hover.revealed)
        #expect(!hover.armed)
        _ = overEmpty(&hover, 3)
        var action = overEmpty(&hover, 4)
        #expect(action == .none)
        // A toggled reveal is not hover's to undo.
        action = outside(&hover, 5)
        #expect(action == .none)
        action = outside(&hover, 6)
        #expect(action == .none)

        hover.rearm()
        _ = overEmpty(&hover, 7)
        action = overEmpty(&hover, 8)
        #expect(action == .reveal)
    }
}
