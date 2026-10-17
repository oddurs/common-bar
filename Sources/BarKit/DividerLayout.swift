import Foundation

/// The status items' autosave names. macOS saves each item's position under its name,
/// so these never change.
public enum ItemName {
    public static let toggle = "toggle"
    public static let divider = "divider"
    public static let alwaysDivider = "alwaysDivider"
    public static let all: Set<String> = [toggle, divider, alwaysDivider]

    /// Spacers are numbered from 1: `spacer1`, `spacer2`, …
    public static func spacer(_ index: Int) -> String { "spacer\(index + 1)" }
}

/// Each status item's saved distance from the right edge of the menu bar; larger is
/// further left. macOS records it as items move, so it is known before they are laid out.
public struct ItemPositions: Equatable, Sendable {
    public var toggle: Double
    public var divider: Double
    public var alwaysDivider: Double

    public init(toggle: Double, divider: Double, alwaysDivider: Double) {
        self.toggle = toggle
        self.divider = divider
        self.alwaysDivider = alwaysDivider
    }

    /// Fills in positions macOS hasn't saved yet. Without one, a new item lands at the far
    /// left, which on a crowded notched display is behind the notch. Each starts just left
    /// of the one before, wherever the user has since moved that one.
    public static func seeded(toggle: Double?, divider: Double?, alwaysDivider: Double?) -> ItemPositions {
        let toggle = toggle ?? 0
        let divider = divider ?? toggle + 1
        return ItemPositions(toggle: toggle, divider: divider, alwaysDivider: alwaysDivider ?? divider + 1)
    }
}

/// How a divider sits in the menu bar. A divider is never removed or hidden with
/// `isVisible`: on Tahoe either one is how the system records a user taking an item out
/// of the menu bar, and it forgets where the item was.
public enum DividerState: Equatable, Sendable {
    /// Stretched far wider than any screen, pushing everything left of it off-screen.
    case stretched
    /// Taken down to nothing: still holding its place, but leaving no gap among the icons.
    case collapsed
    /// A slim mark, so the boundary can be seen while arranging.
    case marker
}

/// Where each divider stands for a given reveal. The chevron never changes; the dividers
/// left of it do the hiding.
public struct DividerLayout: Equatable, Sendable {
    public static let stretchedLength: CGFloat = 10_000

    /// How far a divider stretches to hide: until everything left of it is past the screen's
    /// left edge, with room to spare. Revealed icons then glide in from just off-screen rather
    /// than sweeping across thousands of points. Reaching only past the notch instead would
    /// leave icons on screen behind it, where macOS's overflow rules reshuffle the bar.
    /// `dividerEnd` is the divider's right edge and `padding` what macOS adds to its length.
    public static func reach(dividerEnd: CGFloat, screenMinX: CGFloat, padding: CGFloat) -> CGFloat {
        min(max(dividerEnd - screenMinX - padding + offscreenMargin, 0), stretchedLength)
    }

    static let offscreenMargin: CGFloat = 64

    public var divider: DividerState
    public var alwaysDivider: DividerState

    public init(reveal: Reveal, isPeeking: Bool, positions: ItemPositions, alwaysHidden: Bool) {
        let revealed = isPeeking || !reveal.isCollapsed
        let revealsAll = isPeeking || (revealed && reveal.showsAlwaysHidden)

        if isPeeking {
            divider = .marker
        } else if revealed {
            divider = .collapsed
        } else {
            divider = Self.hiding(inOrder: positions.divider > positions.toggle)
        }

        if !alwaysHidden {
            alwaysDivider = .collapsed
        } else if revealsAll {
            alwaysDivider = .marker
        } else {
            // Stretched while collapsed too, so a reveal never flashes the always-hidden items.
            alwaysDivider = Self.hiding(inOrder: positions.alwaysDivider > positions.divider)
        }
    }

    /// A divider dragged out of order would push the icons meant to stay visible
    /// off-screen with the rest, so it is left out of the way instead of stretched.
    static func hiding(inOrder: Bool) -> DividerState {
        inOrder ? .stretched : .collapsed
    }
}
