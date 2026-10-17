import BarKit
import Foundation
import Testing

@Suite struct ChevronTurnTests {
    let opening = ChevronTurn(from: 0, to: .pi)

    @Test func itStartsWhereItWas() {
        #expect(opening.angle(at: 0).angle == 0)
        #expect(!opening.angle(at: 0).finished)
    }

    @Test func itEndsExactlyHalfARevolutionOn() {
        let end = opening.angle(at: ChevronTurn.duration)
        #expect(abs(end.angle - .pi) < 1e-9)
        #expect(end.finished)
        #expect(opening.angle(at: 5).angle == end.angle)
    }

    @Test func itSwingsPastTheEndByOnlyATouch() {
        let peak = stride(from: 0.0, through: ChevronTurn.duration, by: 0.005).map { opening.angle(at: $0).angle }
            .max()!
        #expect(peak > .pi)
        #expect(peak < .pi * 1.06)
    }

    @Test func mostOfTheTurnHappensEarly() {
        // Ease out: three quarters of the way round within the first third of the time.
        #expect(opening.angle(at: ChevronTurn.duration / 3).angle > .pi * 0.75)
    }

    @Test func turningBackRunsTheOtherWay() {
        let closing = ChevronTurn(from: .pi, to: 0)
        #expect(closing.angle(at: 0).angle == .pi)
        #expect(abs(closing.angle(at: ChevronTurn.duration).angle) < 1e-9)
        #expect(closing.angle(at: 0.1).angle < .pi)
    }

    @Test func aClockBeforeTheStartIsTheStart() {
        #expect(opening.angle(at: -1).angle == 0)
    }
}
