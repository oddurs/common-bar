import BarKit
import CoreGraphics
import Testing

@Suite struct ChevronLocatorTests {
    // Measured on a 1728 pt notched display on Tahoe. The chevron's length is 10 pt and
    // macOS pads every status item to 16 pt more than its length.
    let screenWidth: CGFloat = 1728
    let length: CGFloat = 10
    let chevron = CGRect(x: 1188, y: 0, width: 26, height: 33)
    let focus = CGRect(x: 1506, y: 0, width: 38, height: 33)
    let controlCenter = CGRect(x: 1544, y: 0, width: 42, height: 33)
    let clock = CGRect(x: 1586, y: 0, width: 144, height: 33)

    func find(_ frames: [CGRect]) -> CGRect? {
        ChevronLocator.chevron(among: frames, screenWidth: screenWidth, chevronLength: length)
    }

    @Test func collapsedItIsRightOfTheStretchedDivider() {
        let divider = CGRect(x: -3828, y: 0, width: 5016, height: 33)
        #expect(find([clock, divider, focus, chevron, controlCenter]) == chevron)
    }

    @Test func revealedItIsRightOfTheZeroLengthDivider() {
        let wifi = CGRect(x: 1094, y: 0, width: 38, height: 33)
        let battery = CGRect(x: 1132, y: 0, width: 40, height: 33)
        let divider = CGRect(x: 1172, y: 0, width: 16, height: 33)
        #expect(find([wifi, battery, divider, chevron, focus, controlCenter, clock]) == chevron)
    }

    @Test func theParkedAlwaysHiddenDividerFurtherLeftDoesNotWin() {
        let always = CGRect(x: -4900, y: 0, width: 5016, height: 33)
        let icon = CGRect(x: 116, y: 0, width: 38, height: 33)
        let divider = CGRect(x: 1172, y: 0, width: 16, height: 33)
        #expect(find([always, icon, divider, chevron, focus]) == chevron)
    }

    @Test func neighbouringIconsTenPointsApartAreNotMistakenForIt() {
        let narrow = CGRect(x: 1400, y: 0, width: 32, height: 33)
        let wide = CGRect(x: 1432, y: 0, width: 42, height: 33)
        let divider = CGRect(x: 1172, y: 0, width: 16, height: 33)
        #expect(find([divider, chevron, narrow, wide]) == chevron)
    }

    @Test func itemsThatDoNotTouchAreNotAPair() {
        let divider = CGRect(x: 1160, y: 0, width: 16, height: 33)
        #expect(find([divider, chevron]) == nil)
    }

    @Test func nothingToFindIsNil() {
        #expect(find([]) == nil)
        #expect(find([focus, controlCenter, clock]) == nil)
    }
}
