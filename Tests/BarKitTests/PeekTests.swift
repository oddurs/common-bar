import BarKit
import Foundation
import Testing

@Suite struct PeekTests {
    let start = Date(timeIntervalSinceReferenceDate: 0)

    func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    @Test func commandHeldPastTheDelayPeeks() {
        var peek = Peek()
        var changed = peek.update(commandOnly: true, inMenuBar: true, mouseDown: false, now: at(0))
        #expect(!changed)
        changed = peek.update(commandOnly: true, inMenuBar: true, mouseDown: false, now: at(0.1))
        #expect(!changed)
        changed = peek.update(commandOnly: true, inMenuBar: true, mouseDown: false, now: at(Peek.delay))
        #expect(changed)
        #expect(peek.isPeeking)
    }

    @Test func aBriefCommandPressDoesNotFlashTheBar() {
        var peek = Peek()
        _ = peek.update(commandOnly: true, inMenuBar: true, mouseDown: false, now: at(0))
        _ = peek.update(commandOnly: false, inMenuBar: true, mouseDown: false, now: at(0.1))
        // The hold restarts, so the earlier press doesn't count toward the delay.
        let changed = peek.update(commandOnly: true, inMenuBar: true, mouseDown: false, now: at(0.25))
        #expect(!changed)
        #expect(!peek.isPeeking)
    }

    @Test func commandOutsideTheMenuBarDoesNotPeek() {
        var peek = Peek()
        _ = peek.update(commandOnly: true, inMenuBar: false, mouseDown: false, now: at(0))
        let changed = peek.update(commandOnly: true, inMenuBar: false, mouseDown: false, now: at(1))
        #expect(!changed)
        #expect(!peek.isPeeking)
    }

    @Test func leavingTheMenuBarResetsTheHold() {
        var peek = Peek()
        _ = peek.update(commandOnly: true, inMenuBar: true, mouseDown: false, now: at(0))
        _ = peek.update(commandOnly: true, inMenuBar: false, mouseDown: false, now: at(0.15))
        var changed = peek.update(commandOnly: true, inMenuBar: true, mouseDown: false, now: at(0.3))
        #expect(!changed)
        changed = peek.update(commandOnly: true, inMenuBar: true, mouseDown: false, now: at(0.5))
        #expect(changed)
    }

    @Test func aHeldMouseButtonDoesNotStartAPeek() {
        var peek = Peek()
        _ = peek.update(commandOnly: true, inMenuBar: true, mouseDown: true, now: at(0))
        let changed = peek.update(commandOnly: true, inMenuBar: true, mouseDown: true, now: at(1))
        #expect(!changed)
    }

    func peeking() -> Peek {
        var peek = Peek()
        _ = peek.update(commandOnly: true, inMenuBar: true, mouseDown: false, now: at(0))
        _ = peek.update(commandOnly: true, inMenuBar: true, mouseDown: false, now: at(1))
        return peek
    }

    @Test func releasingCommandMidDragKeepsPeekingUntilTheDrop() {
        var peek = peeking()
        var changed = peek.update(commandOnly: false, inMenuBar: true, mouseDown: true, now: at(2))
        #expect(!changed)
        #expect(peek.isPeeking)
        changed = peek.update(commandOnly: false, inMenuBar: true, mouseDown: false, now: at(3))
        #expect(changed)
        #expect(!peek.isPeeking)
    }

    @Test func peekSurvivesLeavingTheMenuBarWhileCommandIsHeld() {
        var peek = peeking()
        let changed = peek.update(commandOnly: true, inMenuBar: false, mouseDown: false, now: at(2))
        #expect(!changed)
        #expect(peek.isPeeking)
    }

    @Test func anotherModifierEndsThePeek() {
        var peek = peeking()
        // commandOnly is false for ⌘⌥ as well as for no modifiers.
        let changed = peek.update(commandOnly: false, inMenuBar: true, mouseDown: false, now: at(2))
        #expect(changed)
        #expect(!peek.isPeeking)
    }
}
