import BarKit
import Testing

@Suite struct AutoHideTests {
    @Test func eachDelayIsItsStoredSeconds() {
        #expect(AutoHide.fiveSeconds.interval == 5)
        #expect(AutoHide.tenSeconds.interval == 10)
        #expect(AutoHide.thirtySeconds.interval == 30)
        #expect(AutoHide.oneMinute.interval == 60)
    }

    @Test func neverHasNoInterval() {
        #expect(AutoHide.never.interval == nil)
    }

    @Test func aStoredValueReadsBack() {
        for delay in AutoHide.allCases {
            #expect(AutoHide(stored: delay.rawValue) == delay)
        }
    }

    @Test func nothingStoredMeansTheStandardDelay() {
        #expect(AutoHide(stored: nil) == .standard)
        #expect(AutoHide.standard == .tenSeconds)
    }

    @Test func anUnrecognisedValueFallsBackRatherThanNeverHiding() {
        #expect(AutoHide(stored: 7) == .standard)
        #expect(AutoHide(stored: "ten") == .standard)
    }
}
