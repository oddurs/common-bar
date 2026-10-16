import BarKit
import Testing

@Suite struct DividerLayoutTests {
    /// The seeded order: toggle at the right, the divider left of it, the always-hidden divider further left.
    let seeded = ItemPositions(toggle: 0, divider: 1, alwaysDivider: 2)
    let hidden = DividerLayout.hiddenLength
    let visible = DividerLayout.visibleLength

    func layout(
        collapsed: Bool, all: Bool = false, peeking: Bool = false, alwaysHidden: Bool = true,
        _ positions: ItemPositions? = nil
    ) -> DividerLayout {
        var reveal = Reveal(isCollapsed: true)
        _ = reveal.set(collapsed: collapsed, showingAlwaysHidden: all)
        return DividerLayout(
            reveal: reveal, isPeeking: peeking, positions: positions ?? seeded, alwaysHidden: alwaysHidden)
    }

    @Test func withoutAnAlwaysHiddenSectionItsDividerNeverStretchesOrShows() {
        for l in [
            layout(collapsed: true, alwaysHidden: false),
            layout(collapsed: false, alwaysHidden: false),
            layout(collapsed: false, all: true, alwaysHidden: false),
            layout(collapsed: true, peeking: true, alwaysHidden: false),
        ] {
            #expect(l.alwaysDividerLength == 0)
            #expect(!l.showsAlwaysDivider)
        }
    }

    @Test func withoutAnAlwaysHiddenSectionTheChevronStillHidesEverythingLeftOfIt() {
        #expect(layout(collapsed: true, alwaysHidden: false).dividerLength == hidden)
        #expect(layout(collapsed: false, alwaysHidden: false).dividerLength == 0)
    }

    @Test func whileRevealedTheDividerIsParkedSoItLeavesNoGapBesideTheChevron() {
        #expect(layout(collapsed: false).parksDivider)
        #expect(layout(collapsed: true, peeking: true).parksDivider)
        #expect(!layout(collapsed: true).parksDivider)
    }

    @Test func theAlwaysHiddenDividerIsParkedOnlyWhileItsSectionIsOff() {
        #expect(layout(collapsed: false, alwaysHidden: false).parksAlwaysDivider)
        #expect(layout(collapsed: true, alwaysHidden: false).parksAlwaysDivider)
        #expect(!layout(collapsed: false).parksAlwaysDivider)
        #expect(!layout(collapsed: true).parksAlwaysDivider)
        // Out of order with the section on, it stays put rather than losing the user's place.
        #expect(!layout(collapsed: true, ItemPositions(toggle: 2, divider: 3, alwaysDivider: 1)).parksAlwaysDivider)
    }

    @Test func aNormalRevealKeepsTheAlwaysHiddenSectionParkedWhileTheDividerIsAway() {
        // Revealed, the divider waits far left; the always-hidden icons must stay hidden.
        let away = ItemPositions(toggle: 262, divider: ItemPositions.parked, alwaysDivider: 264)
        #expect(layout(collapsed: false, away).alwaysDividerLength == hidden)
    }

    @Test func aParkedDividerIsNeverInPlaceSoHidingPinsItBack() {
        let parked = ItemPositions(toggle: 516, divider: ItemPositions.parked, alwaysDivider: 600)
        #expect(parked.dividerRepin(toggleWidth: 26) == 517)
    }

    @Test func collapsedPushesBothSectionsOff() {
        let l = layout(collapsed: true)
        #expect(l.dividerLength == hidden)
        #expect(l.alwaysDividerLength == hidden)
        #expect(!l.showsAlwaysDivider)
    }

    @Test func aNormalRevealKeepsTheAlwaysHiddenSectionParked() {
        let l = layout(collapsed: false)
        #expect(l.dividerLength == 0)
        #expect(l.alwaysDividerLength == hidden)
        #expect(!l.showsAlwaysDivider)
    }

    @Test func revealingEverythingShowsBothLines() {
        let l = layout(collapsed: false, all: true)
        #expect(l.dividerLength == 0)
        #expect(l.alwaysDividerLength == visible)
        #expect(l.showsAlwaysDivider)
    }

    @Test func peekingShowsBothLinesEvenWhenCollapsed() {
        let l = layout(collapsed: true, peeking: true)
        #expect(l.dividerLength == 0)
        #expect(l.alwaysDividerLength == visible)
        #expect(l.showsAlwaysDivider)
    }

    @Test func aDividerRightOfTheToggleNeverPushesTheToggleOff() {
        let l = layout(collapsed: true, ItemPositions(toggle: 1, divider: 0, alwaysDivider: 2))
        #expect(l.dividerLength == 0)
        #expect(l.alwaysDividerLength == hidden)
    }

    @Test func anAlwaysHiddenDividerRightOfTheChevronStaysUnstretched() {
        let positions = ItemPositions(toggle: 2, divider: 3, alwaysDivider: 1)
        #expect(layout(collapsed: true, positions).alwaysDividerLength == 0)
        #expect(layout(collapsed: false, positions).alwaysDividerLength == 0)
        #expect(layout(collapsed: true, positions).dividerLength == hidden)
    }

    @Test func equalPositionsDoNotPush() {
        let l = layout(collapsed: true, ItemPositions(toggle: 3, divider: 3, alwaysDivider: 3))
        #expect(l.dividerLength == 0)
        #expect(l.alwaysDividerLength == 0)
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
        // Upgrading from a version without the always-hidden divider.
        #expect(
            ItemPositions.seeded(toggle: 40, divider: 90, alwaysDivider: nil)
                == ItemPositions(toggle: 40, divider: 90, alwaysDivider: 91))
        #expect(
            ItemPositions.seeded(toggle: 40, divider: nil, alwaysDivider: nil)
                == ItemPositions(toggle: 40, divider: 41, alwaysDivider: 42))
    }

    // A toggle 40 wide at 431 has its snug neighbour saved at 471, as observed on Tahoe.
    @Test func aDividerSnugAgainstTheToggleStays() {
        let snug = ItemPositions(toggle: 431, divider: 471, alwaysDivider: 600)
        #expect(snug.dividerRepin(toggleWidth: 40) == nil)
    }

    @Test func aFreshlyPlacedDividerStaysUntilMacOSRewritesItsPosition() {
        let placed = ItemPositions(toggle: 431, divider: 432, alwaysDivider: 600)
        #expect(placed.dividerRepin(toggleWidth: 40) == nil)
    }

    @Test func iconsDroppedBetweenTheDividerAndTheChevronAreMovedBehindIt() {
        // Wi-Fi, Battery, and LangSmart (121 pt) dragged just past the chevron.
        let crowded = ItemPositions(toggle: 516, divider: 677, alwaysDivider: 705)
        #expect(crowded.dividerRepin(toggleWidth: 40) == 517)
    }

    @Test func evenANarrowIconBetweenThemCounts() {
        let narrow = ItemPositions(toggle: 0, divider: 60, alwaysDivider: 90)
        #expect(narrow.dividerRepin(toggleWidth: 40) == 1)
    }

    @Test func aDividerRightOfTheToggleIsPutBack() {
        #expect(ItemPositions(toggle: 100, divider: 60, alwaysDivider: 200).dividerRepin(toggleWidth: 40) == 101)
        #expect(ItemPositions(toggle: 100, divider: 100, alwaysDivider: 200).dividerRepin(toggleWidth: 40) == 101)
    }

    @Test func autosaveNamesStayPut() {
        // Renaming any of these would lose every user's arrangement.
        #expect(ItemName.toggle == "toggle")
        #expect(ItemName.divider == "divider")
        #expect(ItemName.alwaysDivider == "alwaysDivider")
        #expect(ItemName.all == ["toggle", "divider", "alwaysDivider"])
    }
}
