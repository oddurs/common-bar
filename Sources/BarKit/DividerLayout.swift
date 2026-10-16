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

    /// The chevron is the boundary: anything dragged past it should hide. So the divider
    /// that does the hiding belongs directly left of the toggle, where macOS saves it at
    /// most one toggle-width further left. Returns where to move it when an icon has been
    /// dropped between them or the divider has strayed right of the toggle, else nil.
    /// A freshly placed divider is saved just 1 further left until macOS rewrites it, so
    /// anything up to a toggle-width away counts as in place.
    public func dividerRepin(toggleWidth: Double) -> Double? {
        let inPlace = divider > toggle && divider <= toggle + toggleWidth + Self.tolerance
        return inPlace ? nil : toggle + 1
    }

    static let tolerance = 2.0
}

/// How wide each divider is and whether the always-hidden line shows. A stretched
/// divider pushes everything left of it off-screen. The first divider never shows: the
/// chevron beside it marks that boundary. With the always-hidden section turned off, its
/// divider stays at zero width, so the icons behind it hide and show with the rest.
public struct DividerLayout: Equatable, Sendable {
    public static let hiddenLength: CGFloat = 10_000
    /// The dotted line's item width; macOS adds its own padding either side.
    public static let visibleLength: CGFloat = 4

    public var dividerLength: CGFloat
    public var alwaysDividerLength: CGFloat
    public var showsAlwaysDivider: Bool

    public init(reveal: Reveal, isPeeking: Bool, positions: ItemPositions, alwaysHidden: Bool) {
        let revealed = isPeeking || !reveal.isCollapsed
        let revealsAll = isPeeking || (revealed && reveal.showsAlwaysHidden)
        guard alwaysHidden else {
            dividerLength = revealed ? 0 : Self.length(hiding: positions.divider > positions.toggle)
            alwaysDividerLength = 0
            showsAlwaysDivider = false
            return
        }
        dividerLength = revealed ? 0 : Self.length(hiding: positions.divider > positions.toggle)
        // Parked while collapsed too, so a reveal never flashes the always-hidden items.
        alwaysDividerLength =
            revealsAll ? Self.visibleLength : Self.length(hiding: positions.alwaysDivider > positions.divider)
        showsAlwaysDivider = revealsAll
    }

    /// A divider dragged out of order would push the items meant to stay visible
    /// off-screen with the rest, including the toggle, so it is left unstretched.
    static func length(hiding inOrder: Bool) -> CGFloat {
        inOrder ? hiddenLength : 0
    }
}
