import BarKit
import Testing

@Suite struct SpacersTests {
    @Test func theCountDefaultsToNone() {
        #expect(Spacers.count(stored: nil) == 0)
    }

    @Test func aStoredCountReadsBack() {
        for n in 0...Spacers.maxCount {
            #expect(Spacers.count(stored: n) == n)
        }
    }

    @Test func outOfRangeCountsAreClamped() {
        #expect(Spacers.count(stored: 40) == Spacers.maxCount)
        #expect(Spacers.count(stored: -2) == 0)
        #expect(Spacers.count(stored: "three") == 0)
    }

    @Test func aNewSpacerStartsJustRightOfTheChevron() {
        #expect(Spacers.seedPosition(toggle: 516) == 515)
    }

    @Test func aChevronAtTheRightEdgeStillGivesAValidPosition() {
        #expect(Spacers.seedPosition(toggle: 0) == 0)
    }

    @Test func spacerNamesStayPut() {
        // Renaming these would lose where every user put their spacers.
        #expect(ItemName.spacer(0) == "spacer1")
        #expect(ItemName.spacer(4) == "spacer5")
    }
}
