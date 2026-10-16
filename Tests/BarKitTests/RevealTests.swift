import BarKit
import Testing

@Suite struct RevealTests {
    @Test func aPlainClickToggles() {
        var reveal = Reveal(isCollapsed: true)
        var next = reveal.afterClick(option: false, alwaysHidden: true)
        #expect(next == (false, false))
        let changed = reveal.set(collapsed: next.collapsed, showingAlwaysHidden: next.showingAlwaysHidden)
        #expect(changed)
        next = reveal.afterClick(option: false, alwaysHidden: true)
        #expect(next == (true, false))
    }

    @Test func anOptionClickOpensEverythingThenClosesIt() {
        var reveal = Reveal(isCollapsed: true)
        let open = reveal.afterClick(option: true, alwaysHidden: true)
        #expect(open == (false, true))
        _ = reveal.set(collapsed: open.collapsed, showingAlwaysHidden: open.showingAlwaysHidden)
        #expect(reveal.showsAlwaysHidden)
        #expect(reveal.afterClick(option: true, alwaysHidden: true) == (true, false))
    }

    @Test func anOptionClickWhileShowingOnlyTheHiddenItemsAddsTheAlwaysHidden() {
        var reveal = Reveal(isCollapsed: true)
        _ = reveal.set(collapsed: false)
        #expect(reveal.afterClick(option: true, alwaysHidden: true) == (false, true))
    }

    @Test func aPlainClickWhileShowingEverythingClosesEverything() {
        var reveal = Reveal(isCollapsed: true)
        _ = reveal.set(collapsed: false, showingAlwaysHidden: true)
        let next = reveal.afterClick(option: false, alwaysHidden: true)
        _ = reveal.set(collapsed: next.collapsed, showingAlwaysHidden: next.showingAlwaysHidden)
        #expect(reveal == Reveal(isCollapsed: true))
    }

    @Test func settingTheSameStateReportsNoChange() {
        var reveal = Reveal(isCollapsed: true)
        var changed = reveal.set(collapsed: true)
        #expect(!changed)
        changed = reveal.set(collapsed: false)
        #expect(changed)
        changed = reveal.set(collapsed: false)
        #expect(!changed)
        changed = reveal.set(collapsed: false, showingAlwaysHidden: true)
        #expect(changed)
    }

    @Test func collapsingNeverLeavesTheAlwaysHiddenShowing() {
        var reveal = Reveal(isCollapsed: false)
        _ = reveal.set(collapsed: false, showingAlwaysHidden: true)
        _ = reveal.set(collapsed: true, showingAlwaysHidden: true)
        #expect(!reveal.showsAlwaysHidden)
    }

    @Test func expandingKeepsTheAlwaysHiddenSetting() {
        var reveal = Reveal(isCollapsed: true)
        reveal.expand()
        #expect(!reveal.isCollapsed)
        #expect(!reveal.showsAlwaysHidden)
    }

    @Test func withoutAnAlwaysHiddenSectionAnOptionClickIsAPlainClick() {
        var reveal = Reveal(isCollapsed: true)
        let open = reveal.afterClick(option: true, alwaysHidden: false)
        #expect(open == (false, false))
        _ = reveal.set(collapsed: open.collapsed, showingAlwaysHidden: open.showingAlwaysHidden)
        #expect(reveal.afterClick(option: true, alwaysHidden: false) == (true, false))
    }
}
