import BarKit
import Testing

@Suite struct DragDemoTests {
    @Test func itStartsWithTheIconRestingRightOfTheChevronAndNothingHeld() {
        let f = DragDemo.frame(at: 0)
        #expect(!f.commandDown)
        #expect(f.progress == 0)
        #expect(f.lift == 0)
        #expect(!f.showsCursor)
        #expect(!f.isFinished)
    }

    @Test func commandIsHeldBeforeTheIconIsPickedUpAndReleasedAfterItHides() {
        #expect(!DragDemo.frame(at: 0.3).commandDown)
        #expect(DragDemo.frame(at: 0.5).commandDown)
        #expect(DragDemo.frame(at: 2.5).commandDown)
        #expect(!DragDemo.frame(at: 2.7).commandDown)
    }

    @Test func theIconIsLiftedWhileItIsDragged() {
        let dragging = DragDemo.frame(at: 1.4)
        #expect(dragging.lift == 1)
        #expect(dragging.showsCursor)
        #expect(dragging.progress > 0 && dragging.progress < 1)
    }

    @Test func theDragMovesSteadilyLeftAndEndsPastTheChevron() {
        let samples = (0...20).map { DragDemo.frame(at: 0.9 + Double($0) * 0.05).progress }
        #expect(samples.first == 0)
        #expect(samples.last! > 0.999)
        #expect(zip(samples, samples.dropFirst()).allSatisfy { $0 <= $1 })
    }

    @Test func droppedPastTheChevronTheIconSettlesThenHides() {
        let settled = DragDemo.frame(at: 2.05)
        #expect(settled.progress == 1)
        #expect(settled.lift == 0)
        #expect(settled.iconOpacity == 1)
        #expect(DragDemo.frame(at: 2.6).iconOpacity == 0)
        #expect(!DragDemo.frame(at: 2.6).showsCursor)
    }

    @Test func everyPassPlaysTheSame() {
        // Sampled between beats: exactly on one, floating-point time can land either side.
        for t in stride(from: 0.05, to: DragDemo.loop, by: 0.1) {
            let first = DragDemo.frame(at: t)
            for pass in 1..<DragDemo.passes {
                let later = DragDemo.frame(at: t + Double(pass) * DragDemo.loop)
                #expect(later.commandDown == first.commandDown)
                #expect(later.showsCursor == first.showsCursor)
                #expect(abs(later.progress - first.progress) < 1e-9)
                #expect(abs(later.lift - first.lift) < 1e-9)
                #expect(abs(later.iconOpacity - first.iconOpacity) < 1e-9)
            }
        }
    }

    @Test func itFinishesAfterThreePasses() {
        #expect(DragDemo.duration == DragDemo.loop * 3)
        #expect(!DragDemo.frame(at: DragDemo.duration - 0.01).isFinished)
        #expect(DragDemo.frame(at: DragDemo.duration).isFinished)
        #expect(DragDemo.frame(at: DragDemo.duration).iconOpacity == 0)
    }

    @Test func aClockBeforeTheStartIsTheFirstFrame() {
        #expect(DragDemo.frame(at: -1) == DragDemo.frame(at: 0))
    }
}
