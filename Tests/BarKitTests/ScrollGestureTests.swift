import BarKit
import Testing

@Suite struct ScrollGestureTests {
    @Test func pullingDownRevealsAndPushingUpHides() {
        // Natural scrolling: fingers moving down report a positive delta.
        var down = ScrollGesture()
        var intent = down.add(deltaY: 10, began: true, timestamp: 1, precise: true, inverted: true)
        #expect(intent == .reveal)
        var up = ScrollGesture()
        intent = up.add(deltaY: -10, began: true, timestamp: 1, precise: true, inverted: true)
        #expect(intent == .hide)
    }

    @Test func classicScrollingFeelsTheSame() {
        var down = ScrollGesture()
        let intent = down.add(deltaY: -10, began: true, timestamp: 1, precise: true, inverted: false)
        #expect(intent == .reveal)
    }

    @Test func smallMovementsAccumulateToTheThreshold() {
        var gesture = ScrollGesture()
        var intent = gesture.add(deltaY: 2, began: true, timestamp: 1, precise: true, inverted: true)
        #expect(intent == nil)
        intent = gesture.add(deltaY: 2, began: false, timestamp: 1.01, precise: true, inverted: true)
        #expect(intent == nil)
        intent = gesture.add(deltaY: 2, began: false, timestamp: 1.02, precise: true, inverted: true)
        #expect(intent == .reveal)
    }

    @Test func oneGestureActsOnce() {
        var gesture = ScrollGesture()
        _ = gesture.add(deltaY: 10, began: true, timestamp: 1, precise: true, inverted: true)
        // Reversing within the same gesture does nothing.
        var intent = gesture.add(deltaY: -30, began: false, timestamp: 1.05, precise: true, inverted: true)
        #expect(intent == nil)
        intent = gesture.add(deltaY: -30, began: true, timestamp: 1.1, precise: true, inverted: true)
        #expect(intent == .hide)
    }

    @Test func aPauseStartsANewGestureForPhaselessWheels() {
        var gesture = ScrollGesture()
        var intent = gesture.add(deltaY: 1, began: false, timestamp: 1, precise: false, inverted: false)
        #expect(intent == .hide)
        intent = gesture.add(deltaY: 1, began: false, timestamp: 1.2, precise: false, inverted: false)
        #expect(intent == nil)
        intent = gesture.add(deltaY: -1, began: false, timestamp: 1.6, precise: false, inverted: false)
        #expect(intent == .reveal)
    }

    @Test func aWheelLineCountsAsTenPoints() {
        var gesture = ScrollGesture()
        var intent = gesture.add(deltaY: -0.5, began: true, timestamp: 1, precise: false, inverted: false)
        #expect(intent == nil)
        intent = gesture.add(deltaY: -0.1, began: false, timestamp: 1.01, precise: false, inverted: false)
        #expect(intent == .reveal)
    }
}
