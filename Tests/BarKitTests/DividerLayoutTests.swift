import BarKit
import Testing

@Suite struct DividerLayoutTests {
    /// The seeded order: toggle at the right, the divider left of it, the always-hidden divider further left.
    let seeded = ItemPositions(toggle: 0, divider: 1, alwaysDivider: 2)

    func layout(
        collapsed: Bool, all: Bool = false, peeking: Bool = false, alwaysHidden: Bool = true,
        _ positions: ItemPositions? = nil
    ) -> DividerLayout {
        var reveal = Reveal(isCollapsed: true)
        _ = reveal.set(collapsed: collapsed, showingAlwaysHidden: all)
        return DividerLayout(
            reveal: reveal, isPeeking: peeking, positions: positions ?? seeded, alwaysHidden: alwaysHidden)
    }

    @Test func aDividerReachesJustPastTheScreensLeftEdge() {
        // Measured on Tahoe: the divider ends at 1136 on a screen starting at 0, and macOS
        // pads each item by 16 pt.
        let reach = DividerLayout.reach(dividerEnd: 1136, screenMinX: 0, padding: 16)
        #expect(reach == 1184)
        // The stretched item then starts 64 pt left of the screen, so every icon is off it.
        #expect(1136 - (reach + 16) == -64)
    }

    @Test func aDividerOnAScreenFurtherRightReachesFromThatScreensEdge() {
        #expect(DividerLayout.reach(dividerEnd: 2864, screenMinX: 1728, padding: 16) == 1184)
    }

    @Test func theReachNeverExceedsTheFullStretch() {
        #expect(DividerLayout.reach(dividerEnd: 20_000, screenMinX: 0, padding: 16) == DividerLayout.stretchedLength)
    }

    @Test func collapsedBothDividersStretch() {
        let l = layout(collapsed: true)
        #expect(l.divider == .stretched)
        #expect(l.alwaysDivider == .stretched)
    }

    @Test func aNormalRevealLeavesNoGapAndKeepsTheAlwaysHiddenSectionHidden() {
        let l = layout(collapsed: false)
        #expect(l.divider == .collapsed)
        #expect(l.alwaysDivider == .stretched)
    }

    @Test func revealingEverythingShowsTheDottedMarker() {
        let l = layout(collapsed: false, all: true)
        #expect(l.divider == .collapsed)
        #expect(l.alwaysDivider == .marker)
    }

    @Test func peekingMarksBothBoundariesForArranging() {
        let l = layout(collapsed: true, peeking: true)
        #expect(l.divider == .marker)
        #expect(l.alwaysDivider == .marker)
    }

    @Test func withoutAnAlwaysHiddenSectionItsDividerIsAlwaysTakenDownToNothing() {
        for l in [
            layout(collapsed: true, alwaysHidden: false),
            layout(collapsed: false, alwaysHidden: false),
            layout(collapsed: false, all: true, alwaysHidden: false),
            layout(collapsed: true, peeking: true, alwaysHidden: false),
        ] {
            #expect(l.alwaysDivider == .collapsed)
        }
        #expect(layout(collapsed: true, peeking: true, alwaysHidden: false).divider == .marker)
    }

    @Test func aDividerRightOfTheChevronIsNotStretched() {
        // Stretching it would push the visible icons, and the chevron, off-screen.
        let l = layout(collapsed: true, ItemPositions(toggle: 1, divider: 0, alwaysDivider: 2))
        #expect(l.divider == .collapsed)
        #expect(l.alwaysDivider == .stretched)
    }

    @Test func anAlwaysHiddenDividerRightOfTheDividerIsNotStretched() {
        let positions = ItemPositions(toggle: 0, divider: 2, alwaysDivider: 1)
        #expect(layout(collapsed: true, positions).alwaysDivider == .collapsed)
        #expect(layout(collapsed: false, positions).alwaysDivider == .collapsed)
        #expect(layout(collapsed: true, positions).divider == .stretched)
    }

    @Test func equalPositionsDoNotStretch() {
        let l = layout(collapsed: true, ItemPositions(toggle: 3, divider: 3, alwaysDivider: 3))
        #expect(l.divider == .collapsed)
        #expect(l.alwaysDivider == .collapsed)
    }
}

@Suite struct ItemPositionsTests {
    @Test func aFreshInstallStartsBesideTheSystemItemsInOrder() {
        #expect(
            ItemPositions.seeded(toggle: nil, divider: nil, alwaysDivider: nil)
                == ItemPositions(toggle: 0, divider: 1, alwaysDivider: 2))
    }

    @Test func savedPositionsAreKept() {
        let saved = ItemPositions(toggle: 40, divider: 90, alwaysDivider: 300)
        #expect(ItemPositions.seeded(toggle: 40, divider: 90, alwaysDivider: 300) == saved)
    }

    @Test func aNewItemStartsLeftOfWhereTheUserMovedThePreviousOne() {
        #expect(
            ItemPositions.seeded(toggle: 40, divider: 90, alwaysDivider: nil)
                == ItemPositions(toggle: 40, divider: 90, alwaysDivider: 91))
        #expect(
            ItemPositions.seeded(toggle: 40, divider: nil, alwaysDivider: nil)
                == ItemPositions(toggle: 40, divider: 41, alwaysDivider: 42))
    }

    @Test func autosaveNamesStayPut() {
        // Renaming any of these would lose every user's arrangement.
        #expect(ItemName.toggle == "toggle")
        #expect(ItemName.divider == "divider")
        #expect(ItemName.alwaysDivider == "alwaysDivider")
        #expect(ItemName.all == ["toggle", "divider", "alwaysDivider"])
    }
}
